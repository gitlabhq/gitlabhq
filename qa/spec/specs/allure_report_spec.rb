# frozen_string_literal: true

require 'allure-rspec'

describe QA::Runtime::AllureReport do
  include Helpers::StubENV

  let(:rspec_config) { double('RSpec::Core::Configuration', 'add_formatter': nil, after: nil) }

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

    let(:png_file) { 'png-file' }
    let(:html_file) { 'html-file' }
    let(:ci_job) { 'ee:relative 5' }

    before do
      stub_env('CI', 'true')
      stub_env('CI_JOB_NAME', ci_job)

      allow(Allure).to receive(:add_attachment)
      allow(File).to receive(:open).with(png_path) { png_file }
      allow(File).to receive(:open).with(html_path) { html_file }

      described_class.configure!
    end

    it 'configures Allure options' do
      aggregate_failures do
        expect(allure_config.results_directory).to eq('tmp/allure-results')
        expect(allure_config.clean_results_directory).to eq(true)
        expect(allure_config.environment_properties).to be_a_kind_of(Hash)
        expect(allure_config.environment).to eq('ee:relative')
      end
    end

    it 'adds rspec and metadata formatter' do
      expect(rspec_config).to have_received(:add_formatter).with(AllureRspecFormatter).ordered
      expect(rspec_config).to have_received(:add_formatter).with(QA::Support::AllureMetadataFormatter).ordered
    end

    it 'configures screenshot saving' do
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
      end
    end
  end
end
