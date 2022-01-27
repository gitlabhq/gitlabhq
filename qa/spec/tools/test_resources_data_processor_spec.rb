# frozen_string_literal: true

RSpec.describe QA::Tools::TestResourceDataProcessor do
  include QA::Support::Helpers::StubEnv

  subject(:processor) { Class.new(described_class).instance }

  let(:info) { 'information' }
  let(:api_response) { {} }
  let(:method) { :api }
  let(:time) { 2 }
  let(:api_path) { resource.api_delete_path }
  let(:resource) { QA::Resource::Project.init { |project| project.id = 1 } }

  let(:result) do
    {
      'QA::Resource::Project' => [{
        info: info,
        api_path: api_path,
        fabrication_method: method,
        fabrication_time: time,
        http_method: :post
      }]
    }
  end

  before do
    processor.collect(resource: resource, info: info, fabrication_method: method, fabrication_time: time)
  end

  describe '.collect' do
    it 'collects and stores resource' do
      expect(processor.resources).to eq(result)
    end
  end

  describe '.write_to_file' do
    let(:resources_file) { Pathname.new(Faker::File.file_name(dir: 'tmp', ext: 'json')) }

    before do
      stub_env('QA_TEST_RESOURCES_CREATED_FILEPATH', resources_file)

      allow(File).to receive(:write)
    end

    it 'writes applicable resources to file' do
      processor.write_to_file

      expect(File).to have_received(:write).with(resources_file, JSON.pretty_generate(result))
    end
  end
end
