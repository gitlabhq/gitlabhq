# frozen_string_literal: true

module QA
  module Support
    class PageErrorChecker
      class << self
        def report!(page, error_code)
          request_id_string = ''
          if error_code == 500
            request_id = parse_five_c_page_request_id(page)
            if request_id
              request_id_string = "\n\n" + Loglinking.failure_metadata(request_id)
            end
          end

          report = if QA::Runtime::Env.browser == :chrome
                     return_chrome_errors(page, error_code)
                   else
                     status_code_report(error_code)
                   end

          raise "Error Code #{error_code}\n\n"\
            "#{report}\n\n"\
            "Path: #{page.current_path}"\
            "#{request_id_string}"
        end

        def parse_five_c_page_request_id(page)
          Nokogiri::HTML.parse(page.html).xpath("/html/body/div/p[1]/code").children.first
        end

        def return_chrome_errors(page, error_code)
          severe_errors = logs(page).select { |log| log.level == 'SEVERE' }
          if severe_errors.none?
            status_code_report(error_code)
          else
            "There #{severe_errors.count == 1 ? 'was' : 'were'} #{severe_errors.count} "\
              "SEVERE level error#{severe_errors.count == 1 ? '' : 's'}:\n\n#{error_report_for(severe_errors)}"
          end
        end

        def status_code_report(error_code)
          "Status code #{error_code} found"
        end

        def check_page_for_error_code(page)
          error_code = 0
          # Test for 404 img alt
          error_code = 404 if Nokogiri::HTML.parse(page.html).xpath("//img").map { |t| t[:alt] }.first.eql?('404')

          # 500 error page in header surrounded by newlines, try to match
          five_hundred_test = Nokogiri::HTML.parse(page.html).xpath("//h1/text()").map.first
          unless five_hundred_test.nil?
            error_code = 500 if five_hundred_test.text.include?('500')
          end
          # GDK shows backtrace rather than error page
          error_code = 500 if Nokogiri::HTML.parse(page.html).xpath("//body//section").map { |t| t[:class] }.first.eql?('backtrace')

          unless error_code == 0
            report!(page, error_code)
          end
        end

        # Log request errors triggered from async api calls from the browser
        #
        # If any errors are found in the session, log them
        # using QA::Runtime::Logger
        # @param [Capybara::Session] page
        def log_request_errors(page)
          return if QA::Runtime::Browser.blank_page?

          url = page.driver.browser.current_url
          QA::Runtime::Logger.debug "Fetching API error cache for #{url}"

          cache = page.execute_script <<~JS
            return !(typeof(Interceptor)==="undefined") ? Interceptor.getCache() : null;
          JS

          return unless cache&.dig('errors')

          grouped_errors = group_errors(cache['errors'])

          errors = grouped_errors.map do |error_metadata, request_id_string|
            "#{error_metadata} -- #{request_id_string}"
          end

          unless errors.nil? || errors.empty?
            QA::Runtime::Logger.error "Interceptor Api Errors\n#{errors.join("\n")}"
          end

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
          page.driver.browser.manage.logs.get(:browser)
        end

        private

        def group_errors(errors)
          errors.each_with_object({}) do |error, memo|
            url = error['url']&.split('?')&.first || 'Unknown url'
            key = "[#{error['status']}] #{error['method']} #{url}"
            memo[key] = "Correlation Id: #{error.dig('headers', 'x-request-id') || 'Correlation Id not found'}"
          end
        end
      end
    end
  end
end
