# frozen_string_literal: true

RSpec.describe QA::Support::PageErrorChecker do
  let(:test_path) { '/test/path' }

  let(:page) { double(Capybara.page) }

  describe '.report!' do
    context 'reports errors' do
      let(:expected_chrome_error) do
        "chrome errors\n\n"\
        "Path: #{test_path}"
      end

      let(:expected_basic_error) do
        "foo status\n\n"\
        "Path: #{test_path}"
      end

      it 'reports error message on chrome browser' do
        allow(QA::Support::PageErrorChecker).to receive(:return_chrome_errors).and_return('chrome errors')
        allow(page).to receive(:current_path).and_return(test_path)
        allow(QA::Runtime::Env).to receive(:browser).and_return(:chrome)

        expect { QA::Support::PageErrorChecker.report!(page, 500) }.to raise_error(RuntimeError, expected_chrome_error)
      end

      it 'reports basic message on non-chrome browser' do
        allow(QA::Support::PageErrorChecker).to receive(:status_code_report).and_return('foo status')
        allow(page).to receive(:current_path).and_return(test_path)
        allow(QA::Runtime::Env).to receive(:browser).and_return(:firefox)

        expect { QA::Support::PageErrorChecker.report!(page, 500) }.to raise_error(RuntimeError, expected_basic_error)
      end
    end
  end

  describe '.return_chrome_errors' do
    context 'returns error message' do
      before do
        single_log = Class.new do
          def level
            'SEVERE'
          end
        end
        stub_const('SingleLog', single_log)
        one_error_mocked_logs = Class.new do
          def self.select
            [SingleLog]
          end
        end
        stub_const('OneErrorMockedLogs', one_error_mocked_logs)
        three_errors_mocked_logs = Class.new do
          def self.select
            [SingleLog, SingleLog, SingleLog]
          end
        end
        stub_const('ThreeErrorsMockedLogs', three_errors_mocked_logs)
        no_error_mocked_logs = Class.new do
          def self.select
            []
          end
        end
        stub_const('NoErrorMockedLogs', no_error_mocked_logs)
      end

      let(:expected_single_error) do
        "There was 1 SEVERE level error:\n\n"\
        "bar foo"
      end

      let(:expected_multiple_error) do
        "There were 3 SEVERE level errors:\n\n"\
        "bar foo\n"\
        "foo\n"\
        "bar"
      end

      it 'returns status code report on no severe errors found' do
        allow(QA::Support::PageErrorChecker).to receive(:logs).with(page).and_return(NoErrorMockedLogs)
        allow(QA::Support::PageErrorChecker).to receive(:status_code_report).with('123').and_return('Test Status Code return 123')

        expect(QA::Support::PageErrorChecker.return_chrome_errors(page, '123')).to eq('Test Status Code return 123')
      end

      it 'returns report on 1 severe error found' do
        allow(QA::Support::PageErrorChecker).to receive(:error_report_for).with([SingleLog]).and_return('bar foo')
        allow(QA::Support::PageErrorChecker).to receive(:logs).with(page).and_return(OneErrorMockedLogs)
        allow(page).to receive(:current_path).and_return(test_path)

        expect(QA::Support::PageErrorChecker.return_chrome_errors(page, '123')).to eq(expected_single_error)
      end

      it 'returns report on multiple severe errors found' do
        allow(QA::Support::PageErrorChecker).to receive(:error_report_for)
                                                    .with([SingleLog, SingleLog, SingleLog]).and_return("bar foo\nfoo\nbar")
        allow(QA::Support::PageErrorChecker).to receive(:logs).with(page).and_return(ThreeErrorsMockedLogs)
        allow(page).to receive(:current_path).and_return(test_path)

        expect(QA::Support::PageErrorChecker.return_chrome_errors(page, '123')).to eq(expected_multiple_error)
      end
    end
  end

  describe '.check_page_for_error_code' do
    require 'nokogiri'
    before do
      nokogiri_parse = Class.new do
        def self.parse(str)
          Nokogiri::HTML.parse(str)
        end
      end
      stub_const('NokogiriParse', nokogiri_parse)
    end
    let(:error_404_str) do
      "<div class=\"error\">"\
        "<img src=\"404.png\" alt=\"404\" />"\
      "</div>"
    end

    let(:error_500_str) { "<h1>   500   </h1>"}
    let(:backtrace_str) {"<body><section class=\"backtrace\">foo</section></body>"}
    let(:no_error_str) {"<body>no 404 or 500 or backtrace</body>"}

    it 'calls report with 404 if 404 found' do
      allow(page).to receive(:html).and_return(error_404_str)
      allow(Nokogiri::HTML).to receive(:parse).with(error_404_str).and_return(NokogiriParse.parse(error_404_str))

      expect(QA::Support::PageErrorChecker).to receive(:report!).with(page, 404)
      QA::Support::PageErrorChecker.check_page_for_error_code(page)
    end
    it 'calls report with 500 if 500 found' do
      allow(page).to receive(:html).and_return(error_500_str)
      allow(Nokogiri::HTML).to receive(:parse).with(error_500_str).and_return(NokogiriParse.parse(error_500_str))

      expect(QA::Support::PageErrorChecker).to receive(:report!).with(page, 500)
      QA::Support::PageErrorChecker.check_page_for_error_code(page)
    end
    it 'calls report with 500 if GDK backtrace found' do
      allow(page).to receive(:html).and_return(backtrace_str)
      allow(Nokogiri::HTML).to receive(:parse).with(backtrace_str).and_return(NokogiriParse.parse(backtrace_str))

      expect(QA::Support::PageErrorChecker).to receive(:report!).with(page, 500)
      QA::Support::PageErrorChecker.check_page_for_error_code(page)
    end
    it 'does not call report if no 404, 500 or backtrace found' do
      allow(page).to receive(:html).and_return(no_error_str)
      allow(Nokogiri::HTML).to receive(:parse).with(no_error_str).and_return(NokogiriParse.parse(no_error_str))

      expect(QA::Support::PageErrorChecker).not_to receive(:report!)
      QA::Support::PageErrorChecker.check_page_for_error_code(page)
    end
  end

  describe '.error_report_for' do
    before do
      logs_class_one = Class.new do
        def self.message
          'foo\\n'
        end
      end
      stub_const('LogOne', logs_class_one)
      logs_class_two = Class.new do
        def self.message
          'bar'
        end
      end
      stub_const('LogTwo', logs_class_two)
    end

    it 'returns error report array of log messages' do
      expect(QA::Support::PageErrorChecker.error_report_for([LogOne, LogTwo]))
          .to eq(%W(foo\n bar))
    end
  end

  describe '.logs' do
    before do
      logs_class = Class.new do
        def self.get(level)
          "logs at #{level} level"
        end
      end
      stub_const('Logs', logs_class)
      manage_class = Class.new do
        def self.logs
          Logs
        end
      end
      stub_const('Manage', manage_class)
      browser_class = Class.new do
        def self.manage
          Manage
        end
      end
      stub_const('Browser', browser_class)
      driver_class = Class.new do
        def self.browser
          Browser
        end
      end
      stub_const('Driver', driver_class)
    end

    it 'gets driver browser logs' do
      allow(page).to receive(:driver).and_return(Driver)

      expect(QA::Support::PageErrorChecker.logs(page)).to eq('logs at browser level')
    end
  end

  describe '.status_code_report' do
    it 'returns a string message containing the status code' do
      expect(QA::Support::PageErrorChecker.status_code_report(1234)).to eq('Status code 1234 found')
    end
  end
end
