# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Static Site Editor' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:sse_path) { project_show_sse_path(project, 'master/README.md') }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context "when no config file is present" do
    before do
      visit sse_path
    end

    it 'renders SSE page with all generated config values and default config file values' do
      node = page.find('#static-site-editor')

      # assert generated config values are present
      expect(node['data-base-url']).to eq("/#{project.full_path}/-/sse/master%2FREADME.md")
      expect(node['data-branch']).to eq('master')
      expect(node['data-commit-id']).to match(/\A[0-9a-f]{40}\z/)
      expect(node['data-is-supported-content']).to eq('true')
      expect(node['data-merge-requests-illustration-path'])
        .to match(%r{/assets/illustrations/merge_requests-.*\.svg})
      expect(node['data-namespace']).to eq(project.namespace.full_path)
      expect(node['data-project']).to eq(project.path)
      expect(node['data-project-id']).to eq(project.id.to_s)

      # assert default config file values are present
      expect(node['data-image-upload-path']).to eq('source/images')
      expect(node['data-mounts']).to eq('[{"source":"source","target":""}]')
      expect(node['data-static-site-generator']).to eq('middleman')
    end
  end

  context "when a config file is present" do
    let(:config_file_yml) do
      <<~YAML
        image_upload_path: custom-image-upload-path
        mounts:
          - source: source1
            target: ""
          - source: source2
            target: target2
        static_site_generator: middleman
      YAML
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).and_return(config_file_yml)
      end

      visit sse_path
    end

    it 'renders Static Site Editor page values read from config file' do
      node = page.find('#static-site-editor')

      # assert user-specified config file values are present
      expected_mounts = '[{"source":"source1","target":""},{"source":"source2","target":"target2"}]'
      expect(node['data-image-upload-path']).to eq('custom-image-upload-path')
      expect(node['data-mounts']).to eq(expected_mounts)
      expect(node['data-static-site-generator']).to eq('middleman')
    end
  end
end
