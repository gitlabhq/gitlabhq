# frozen_string_literal: true

require 'spec_helper'

describe SearchController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples_for 'when the user cannot read cross project' do |action, params|
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(user, :read_cross_project, :global) { false }
    end

    it 'blocks access without a project_id' do
      get action, params: params

      expect(response).to have_gitlab_http_status(403)
    end

    it 'allows access with a project_id' do
      get action, params: params.merge(project_id: create(:project, :public).id)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  shared_examples_for 'with external authorization service enabled' do |action, params|
    let(:project) { create(:project, namespace: user.namespace) }
    let(:note) { create(:note_on_issue, project: project) }

    before do
      enable_external_authorization_service_check
    end

    it 'renders a 403 when no project is given' do
      get action, params: params

      expect(response).to have_gitlab_http_status(403)
    end

    it 'renders a 200 when a project was set' do
      get action, params: params.merge(project_id: project.id)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'GET #show' do
    it_behaves_like 'when the user cannot read cross project', :show, { search: 'hello' } do
      it 'still allows accessing the search page' do
        get :show

        expect(response).to have_gitlab_http_status(200)
      end
    end

    it_behaves_like 'with external authorization service enabled', :show, { search: 'hello' }

    context 'uses the right partials depending on scope' do
      using RSpec::Parameterized::TableSyntax
      render_views

      set(:project) { create(:project, :public, :repository, :wiki_repo) }

      before do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
      end

      subject { get(:show, params: { project_id: project.id, scope: scope, search: 'merge' }) }

      where(:partial, :scope) do
        '_blob'        | :blobs
        '_wiki_blob'   | :wiki_blobs
        '_commit'      | :commits
      end

      with_them do
        it do
          project_wiki = create(:project_wiki, project: project, user: user)
          create(:wiki_page, wiki: project_wiki, attrs: { title: 'merge', content: 'merge' })

          expect(subject).to render_template("search/results/#{partial}")
        end
      end
    end

    context 'global search' do
      render_views

      it 'omits pipeline status from load' do
        project = create(:project, :public)
        expect(Gitlab::Cache::Ci::ProjectPipelineStatus).not_to receive(:load_in_batch_for_projects)

        get :show, params: { scope: 'projects', search: project.name }

        expect(assigns[:search_objects].first).to eq project
      end
    end

    it 'finds issue comments' do
      project = create(:project, :public)
      note = create(:note_on_issue, project: project)

      get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

      expect(assigns[:search_objects].first).to eq note
    end

    context 'on restricted projects' do
      context 'when signed out' do
        before do
          sign_out(user)
        end

        it "doesn't expose comments on issues" do
          project = create(:project, :public, :issues_private)
          note = create(:note_on_issue, project: project)

          get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

          expect(assigns[:search_objects].count).to eq(0)
        end
      end

      it "doesn't expose comments on merge_requests" do
        project = create(:project, :public, :merge_requests_private)
        note = create(:note_on_merge_request, project: project)

        get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

        expect(assigns[:search_objects].count).to eq(0)
      end

      it "doesn't expose comments on snippets" do
        project = create(:project, :public, :snippets_private)
        note = create(:note_on_project_snippet, project: project)

        get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

        expect(assigns[:search_objects].count).to eq(0)
      end
    end
  end

  describe 'GET #count' do
    it_behaves_like 'when the user cannot read cross project', :count, { search: 'hello', scope: 'projects' }
    it_behaves_like 'with external authorization service enabled', :count, { search: 'hello', scope: 'projects' }

    it 'returns the result count for the given term and scope' do
      create(:project, :public, name: 'hello world')
      create(:project, :public, name: 'foo bar')

      get :count, params: { search: 'hello', scope: 'projects' }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq({ 'count' => '1' })
    end

    it 'raises an error if search term is missing' do
      expect do
        get :count, params: { scope: 'projects' }
      end.to raise_error(ActionController::ParameterMissing)
    end

    it 'raises an error if search scope is missing' do
      expect do
        get :count, params: { search: 'hello' }
      end.to raise_error(ActionController::ParameterMissing)
    end
  end

  describe 'GET #autocomplete' do
    it_behaves_like 'when the user cannot read cross project', :autocomplete, { term: 'hello' }
    it_behaves_like 'with external authorization service enabled', :autocomplete, { term: 'hello' }
  end
end
