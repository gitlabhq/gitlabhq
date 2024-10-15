# frozen_string_literal: true

module QA
  module Support
    class PageErrorChecker
      PageError = Class.new(StandardError)

      class << self
        def report!(page, error_code)
          request_id_string = ''
          if error_code == 500
            request_id = parse_five_c_page_request_id(page)
            request_id_string = "\n\n#{Loglinking.failure_metadata(request_id)}" if request_id
          end

          report = if QA::Runtime::Env.browser == :chrome
                     return_chrome_errors(page, error_code)
                   else
                     status_code_report(error_code)
                   end

          raise(PageError, <<~MSG)
            Error Code: #{error_code}

            #{report}

            Path: #{page.current_path}#{request_id_string}
          MSG
        end

        def parse_five_c_page_request_id(page)
          page_html(page).xpath("/html/body/div/p[1]/code").children.first
        end

        def return_chrome_errors(page, error_code)
          severe_errors = logs(page).select { |log| log.level == 'SEVERE' }
          if severe_errors.none?
            status_code_report(error_code)
          else
            "There #{severe_errors.count == 1 ? 'was' : 'were'} #{severe_errors.count} " \
              "SEVERE level error#{severe_errors.count == 1 ? '' : 's'}:\n\n#{error_report_for(severe_errors)}"
          end
        end

        def status_code_report(error_code)
          "Status code #{error_code} found"
        end

        # rubocop:disable Rails/Pluck
        def check_page_for_error_code(page)
          QA::Runtime::Logger.debug "Performing page error check!"

          # Test for 404 img alt
          error_code = page_html(page).xpath("//img").map { |t| t[:alt] }.first
          return report!(page, 404) if error_code && error_code.include?('404')

          # 500 error page in header surrounded by newlines, try to match
          five_hundred_test = page_html(page).xpath("//h1/text()").map.first
          five_hundred_title = page_html(page).xpath("//head/title/text()").map.first
          if five_hundred_test&.text&.include?('500') && five_hundred_title&.text.eql?('Something went wrong (500)')
            return report!(page, 500)
          end

          # GDK shows backtrace rather than error page
          report!(page, 500) if page_html(page).xpath("//body//section").map { |t| t[:class] }.first.eql?('backtrace')
        rescue StandardError => e
          raise e if e.is_a?(PageError)

          QA::Runtime::Logger.error("Page error check raised error `#{e.class}`: #{e.message}")
        end

        # rubocop:enable Rails/Pluck

        # Log request errors triggered from async api calls from the browser
        #
        # If any errors are found in the session, log them
        # using QA::Runtime::Logger
        # @param [Capybara::Session] page
        def log_request_errors(page)
          return if !QA::Runtime::Env.can_intercept? || QA::Runtime::Browser.blank_page?

          url = page.driver.browser.current_url
          QA::Runtime::Logger.debug "Fetching API error cache for #{url}"

          cache = page.execute_script <<~JS
            return !(typeof(Interceptor)==="undefined") ? Interceptor.getCache() : null;
          JS

          return unless cache&.dig('errors')

          grouped_errors = group_errors(cache['errors'])

          errors = grouped_errors.map do |error_metadata, error_body|
            "#{error_metadata} -- #{error_body[:request_id_string]}\n#{error_body[:error_body]}"
          end

          QA::Runtime::Logger.warn "Interceptor Api Errors\n#{errors.join("\n")}" unless errors.nil? || errors.empty?

          # clear the cache after logging the errors
          page.execute_script <<~JS
            Interceptor && Interceptor.saveCache({});
          JS
        end

        def error_report_for(logs)
          logs
            .map(&:message)
            .map { |message| message.gsub('\\n', "\n") }
        end

        def logs(page)
          page.driver.browser.logs.get(:browser)
        end

        private

        def page_html(page)
          Nokogiri::HTML.parse(page.html)
        end

        def group_errors(errors)
          errors.each_with_object({}) do |error, memo|
            url = error['url']&.split('?')&.first || 'Unknown url'
            key = "[#{error['status']}] #{error['method']} #{url}"
            request_id_string = "Correlation Id: #{error.dig('headers', 'x-request-id') || 'Correlation Id not found'}"
            memo[key] = {
              request_id_string: request_id_string,
              error_body: error['errorData']
            }
          end
        end
      end
    end
  end
end
