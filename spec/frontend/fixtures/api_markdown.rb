# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequests, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  fixture_subdir = 'api/markdown'

  before(:all) do
    clean_frontend_fixtures(fixture_subdir)
  end

  markdown_examples = begin
    yaml_file_path = File.expand_path('api_markdown.yml', __dir__)
    yaml = File.read(yaml_file_path)
    YAML.safe_load(yaml, symbolize_names: true)
  end

  markdown_examples.each do |markdown_example|
    name = markdown_example.fetch(:name)

    context "for #{name}" do
      let(:markdown) { markdown_example.fetch(:markdown) }

      it "#{fixture_subdir}/#{name}.json" do
        post api("/markdown"), params: { text: markdown }

        expect(response).to be_successful
      end
    end
  end
end
