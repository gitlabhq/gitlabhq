# frozen_string_literal: true

require 'allure-rspec'

describe QA::Runtime::AllureReport do
  include Helpers::StubENV

  let(:rspec_config) { double('RSpec::Core::Configuration', 'formatter=': nil, after: nil) }
  let(:rspec_example) do
    double(
      'RSpec::Core::Example',
      tms: nil,
      issue: nil,
      add_link: nil,
      attempts: 0,
      file_path: 'file/path/spec.rb',
      metadata: {
        testcase: 'testcase',
        quarantine: { issue: 'issue' }
      }
    )
  end

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
    allow(rspec_config).to receive(:after).and_yield(rspec_example)
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
    let(:ci_job_url) { 'url' }

    before do
      stub_env('CI', 'true')
      stub_env('CI_JOB_NAME', ci_job)
      stub_env('CI_JOB_URL', ci_job_url)

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

    it 'adds rspec formatter' do
      expect(rspec_config).to have_received(:formatter=).with(AllureRspecFormatter)
    end

    it 'configures after block' do
      aggregate_failures do
        expect(rspec_example).to have_received(:tms).with('Testcase', 'testcase')
        expect(rspec_example).to have_received(:issue).with('Quarantine issue', 'issue')
        expect(rspec_example).to have_received(:add_link).with(name: "Job(#{ci_job})", url: ci_job_url)
        expect(rspec_example).to have_received(:issue).with(
          'Failure issues',
          'https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&search=spec.rb'
        )
      end
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
