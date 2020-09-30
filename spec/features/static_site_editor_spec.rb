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

    it 'renders Static Site Editor page with all generated config values and default config file values' do
      node = page.find('#static-site-editor')

      # assert generated config values are present
      expect(node['data-base-url']).to eq("/#{project.full_path}/-/sse/master%2FREADME.md")
      expect(node['data-branch']).to eq('master')
      expect(node['data-commit-id']).to match(/\A[0-9a-f]{40}\z/)
      expect(node['data-is-supported-content']).to eq('true')
      expect(node['data-merge-requests-illustration-path']).to match(%r{/assets/illustrations/merge_requests-.*\.svg})
      expect(node['data-namespace']).to eq(project.namespace.full_path)
      expect(node['data-project']).to eq(project.path)
      expect(node['data-project-id']).to eq(project.id.to_s)

      # assert default config file values are present
      expect(node['data-static-site-generator']).to eq('middleman')
    end
  end

  context "when a config file is present" do
    let(:config_file_yml) do
      # NOTE: There isn't currently any support for a non-default config value, but this can be
      #       manually tested by temporarily adding an additional supported valid value in
      #       lib/gitlab/static_site_editor/config/file_config/entry/static_site_generator.rb.
      #       As soon as there is a real non-default value supported by the config file,
      #       this test can be updated to include it.
      <<-EOS
        static_site_generator: middleman
      EOS
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
      expect(node['data-static-site-generator']).to eq('middleman')
    end
  end
end
