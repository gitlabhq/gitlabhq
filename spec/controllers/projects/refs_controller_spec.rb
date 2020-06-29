# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RefsController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  describe 'GET #logs_tree' do
    let(:path) { 'foo/bar/baz.html' }

    def default_get(format = :html)
      get :logs_tree,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: 'master',
            path: path
          },
          format: format
    end

    def xhr_get(format = :html, params = {})
      get :logs_tree, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: 'master',
        path: path,
        format: format
      }.merge(params), xhr: true
    end

    it 'never throws MissingTemplate' do
      expect { default_get }.not_to raise_error
      expect { xhr_get(:json) }.not_to raise_error
      expect { xhr_get }.not_to raise_error
    end

    it 'renders 404 for HTML requests' do
      xhr_get

      expect(response).to be_not_found
    end

    context 'when json is requested' do
      it 'renders JSON' do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        xhr_get(:json)

        expect(response).to be_successful
        expect(json_response).to be_kind_of(Array)
      end

      it 'caches tree summary data', :use_clean_rails_memory_store_caching do
        expect_next_instance_of(::Gitlab::TreeSummary) do |instance|
          expect(instance).to receive_messages(summarize: ['logs'], next_offset: 50, more?: true)
        end

        xhr_get(:json, offset: 25)

        cache_key = "projects/#{project.id}/logs/#{project.commit.id}/#{path}/25"
        expect(Rails.cache.fetch(cache_key)).to eq(['logs', 50])
        expect(response.headers['More-Logs-Offset']).to eq("50")
      end
    end
  end
end
