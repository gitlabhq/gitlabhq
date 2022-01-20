# frozen_string_literal: true

module QA
  module Support
    class PageErrorChecker
      class << self
        def report!(page, error_code)
          report = if QA::Runtime::Env.browser == :chrome
                     return_chrome_errors(page, error_code)
                   else
                     status_code_report(error_code)
                   end

          raise "#{report}\n\n"\
            "Path: #{page.current_path}"
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
          five_hundred_test = Nokogiri::HTML.parse(page.html).xpath("//h1").map.first
          unless five_hundred_test.nil?
            error_code = 500 if five_hundred_test.text.include?('500')
          end
          # GDK shows backtrace rather than error page
          error_code = 500 if Nokogiri::HTML.parse(page.html).xpath("//body//section").map { |t| t[:class] }.first.eql?('backtrace')

          unless error_code == 0
            report!(page, error_code)
          end
        end

        def error_report_for(logs)
          logs
              .map(&:message)
              .map { |message| message.gsub('\\n', "\n") }
        end

        def logs(page)
          page.driver.browser.manage.logs.get(:browser)
        end
      end
    end
  end
end
