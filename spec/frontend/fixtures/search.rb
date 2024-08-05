# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  render_views

  let_it_be(:user) { create(:user) }

  before do
    # with this feature flag on the blob search results
    # are moved to vue and are tested using jest
    stub_feature_flags(zoekt_multimatch_frontend: false)
    sign_in(user)
  end

  it 'search/show.html' do
    get :show

    expect(response).to be_successful
  end

  context 'search within a project' do
    let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
    let(:project) { create(:project, :public, :repository, namespace: namespace, path: 'search-project') }
    let(:blobs) do
      Kaminari.paginate_array(
        [
          Gitlab::Search::FoundBlob.new(
            path: 'CHANGELOG',
            basename: 'CHANGELOG',
            ref: 'master',
            data: "hello\nworld\nfoo\nSend # this is the highligh\nbaz\nboo\nbat",
            project: project,
            project_id: project.id,
            startline: 2),
          Gitlab::Search::FoundBlob.new(
            path: 'CONTRIBUTING',
            basename: 'CONTRIBUTING',
            ref: 'master',
            data: "hello\nworld\nfoo\nSend # this is the highligh\nbaz\nboo\nbat",
            project: project,
            project_id: project.id,
            startline: 2),
          Gitlab::Search::FoundBlob.new(
            path: 'README',
            basename: 'README',
            ref: 'master',
            data: "foo\nSend # this is the highlight\nbaz\nboo\nbat",
            project: project,
            project_id: project.id,
            startline: 2),
          Gitlab::Search::FoundBlob.new(
            path: 'test',
            basename: 'test',
            ref: 'master',
            data: "foo\nSend # this is the highlight\nbaz\nboo\nbat",
            project: project,
            project_id: project.id,
            startline: 2)
        ],
        total_count: 4,
        limit: 4,
        offset: 0
      )
    end

    before do
      project.add_developer(user)
    end

    it 'search/blob_search_result.html' do
      allow_next_instance_of(SearchServicePresenter) do |search_service|
        allow(search_service).to receive(:search_objects).and_return(blobs)
      end

      get :show, params: {
        search: 'Send',
        project_id: project.id,
        scope: :blobs
      }

      expect(response).to be_successful
    end
  end
end
