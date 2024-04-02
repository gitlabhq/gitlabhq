# frozen_string_literal: true

describe QA::Runtime::AllureReport do
  include QA::Support::Helpers::StubEnv

  let(:rspec_config) { instance_double('RSpec::Core::Configuration', add_formatter: nil, append_after: nil) }

  let(:png_path) { 'png_path' }
  let(:html_path) { 'html_path' }

  let(:allure_config) do
    # need to mock config in case the test itself is executed with allure reporting enabled
    AllureRspec::RspecConfig.send(:new).tap do |conf|
      conf.instance_variable_set(:@allure_config, Allure::Config.send(:new))
    end
  end

  before do
    stub_env('QA_GENERATE_ALLURE_REPORT', generate_report)

    allow(AllureRspec).to receive(:configure).and_yield(allure_config)
    allow(RSpec).to receive(:configure).and_yield(rspec_config)
    allow(Capybara::Screenshot).to receive(:after_save_screenshot).and_yield(png_path)
    allow(Capybara::Screenshot).to receive(:after_save_html).and_yield(html_path)
  end

  context 'with report generation disabled' do
    let(:generate_report) { 'false' }

    it 'does not perform configuration' do
      aggregate_failures do
        expect(described_class.configure!).to be_nil

        expect(AllureRspec).not_to have_received(:configure)
        expect(RSpec).not_to have_received(:configure)
        expect(Capybara::Screenshot).not_to have_received(:after_save_screenshot)
        expect(Capybara::Screenshot).not_to have_received(:after_save_html)
      end
    end
  end

  context 'with report generation enabled' do
    let(:generate_report) { 'true' }

    let(:session) { instance_double('Capybara::Session') }
    let(:attributes) { class_spy('Runtime::Scenario') }
    let(:version_response) { instance_double('HTTPResponse', code: 200, body: versions.to_json) }

    let(:png_file) { 'png-file' }
    let(:html_file) { 'html-file' }
    let(:ci_job) { 'ee:relative 5' }
    let(:versions) { { version: '14', revision: '6ced31db947' } }
    let(:browser_log) { ['log message 1', 'log message 2'] }

    before do
      stub_env('CI', 'true')
      stub_env('CI_JOB_NAME', ci_job)
      stub_env('GITLAB_QA_ADMIN_ACCESS_TOKEN', 'token')

      stub_const('QA::Runtime::Scenario', attributes)

      allow(Allure).to receive(:add_attachment)
      allow(File).to receive(:open).with(png_path) { png_file }
      allow(File).to receive(:open).with(html_path) { html_file }
      allow(RestClient::Request).to receive(:execute) { version_response }
      allow(attributes).to receive(:gitlab_address).and_return("https://gitlab.com")

      allow(Capybara).to receive(:current_session).and_return(session)
      allow(session).to receive_message_chain('driver.browser.logs.get').and_return(browser_log)

      described_class.configure!
    end

    it 'configures Allure options' do
      aggregate_failures do
        expect(allure_config.results_directory).to eq('tmp/allure-results')
        expect(allure_config.clean_results_directory).to eq(false)
        expect(allure_config.environment_properties.call).to eq(versions)
        expect(allure_config.environment).to eq('ee:relative')
      end
    end

    it 'adds rspec and metadata formatter' do
      expect(rspec_config).to have_received(:add_formatter).with(
        QA::Support::Formatters::AllureMetadataFormatter
      ).ordered
      expect(rspec_config).to have_received(:add_formatter).with(AllureRspecFormatter).ordered
    end

    it 'configures attachments saving' do
      expect(rspec_config).to have_received(:append_after) do |&arg|
        arg.call
      end

      aggregate_failures do
        expect(Allure).to have_received(:add_attachment).with(
          name: 'screenshot',
          source: png_file,
          type: Allure::ContentType::PNG,
          test_case: true
        )
        expect(Allure).to have_received(:add_attachment).with(
          name: 'html',
          source: html_file,
          type: 'text/html',
          test_case: true
        )
        expect(Allure).to have_received(:add_attachment).with(
          name: 'browser.log',
          source: browser_log.join("\n\n"),
          type: Allure::ContentType::TXT,
          test_case: true
        )
      end
    end
  end
end
