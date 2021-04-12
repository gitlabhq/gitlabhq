# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::CreationsController do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }
  let(:fork_project) { create(:forked_project_with_submodules) }
  let(:get_diff_params) do
    {
      namespace_id: fork_project.namespace.to_param,
      project_id: fork_project,
      merge_request: {
        source_branch: 'remove-submodule',
        target_branch: 'master'
      }
    }
  end

  before do
    fork_project.add_maintainer(user)
    Projects::ForkService.new(project, user).execute(fork_project)
    sign_in(user)
  end

  describe 'GET new' do
    context 'merge request that removes a submodule' do
      it 'renders new merge request widget template' do
        get :new, params: get_diff_params

        expect(response).to be_successful
      end
    end

    context 'merge request with some commits' do
      render_views

      let(:large_diff_params) do
        {
          namespace_id: fork_project.namespace.to_param,
          project_id: fork_project,
          merge_request: {
            source_branch: 'master',
            target_branch: 'fix'
          }
        }
      end

      describe 'with artificial limits' do
        before do
          # Load MergeRequestdiff so stub_const won't override it with its own definition
          # See https://github.com/rspec/rspec-mocks/issues/1079
          stub_const("#{MergeRequestDiff}::COMMITS_SAFE_SIZE", 2)
        end

        it 'limits total commits' do
          get :new, params: large_diff_params

          expect(response).to be_successful

          total = assigns(:total_commit_count)
          expect(assigns(:commits)).to be_an Array
          expect(total).to be > 0
          expect(assigns(:hidden_commit_count)).to be > 0
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to match %r(<span class="commits-count">2 commits</span>)
        end
      end

      it 'shows total commits' do
        get :new, params: large_diff_params

        expect(response).to be_successful

        total = assigns(:total_commit_count)
        expect(assigns(:commits)).to be_an CommitCollection
        expect(total).to be > 0
        expect(assigns(:hidden_commit_count)).to eq(0)
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to match %r(<span class="commits-count">#{total} commits</span>)
      end
    end
  end

  describe 'GET diffs' do
    context 'when merge request cannot be created' do
      it 'does not assign diffs var' do
        allow_next_instance_of(MergeRequest) do |instance|
          allow(instance).to receive(:can_be_created).and_return(false)
        end

        get :diffs, params: get_diff_params.merge(format: 'json')

        expect(response).to be_successful
        expect(assigns[:diffs]).to be_nil
      end
    end
  end

  describe 'GET pipelines' do
    before do
      create(:ci_pipeline, sha: fork_project.commit('remove-submodule').id,
                           ref: 'remove-submodule',
                           project: fork_project)
    end

    it 'renders JSON including serialized pipelines' do
      get :pipelines, params: get_diff_params.merge(format: 'json')

      expect(response).to be_ok
      expect(json_response).to have_key 'pipelines'
      expect(json_response['pipelines']).not_to be_empty
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        format: 'json'
      }

      get :diff_for_path, params: params.merge(extra_params)
    end

    let(:existing_path) { 'files/ruby/feature.rb' }

    context 'when both branches are in the same project' do
      it 'disables diff notes' do
        diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_branch: 'feature', target_branch: 'master' })

        expect(assigns(:diff_notes_disabled)).to be_truthy
      end

      it 'only renders the diffs for the path given' do
        expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
          expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
          meth.call(diffs)
        end

        diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_branch: 'feature', target_branch: 'master' })
      end
    end

    context 'when the source branch is in a different project to the target' do
      let(:other_project) { create(:project, :repository) }

      before do
        other_project.add_maintainer(user)
      end

      context 'when the path exists in the diff' do
        it 'disables diff notes' do
          diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })

          expect(assigns(:diff_notes_disabled)).to be_truthy
        end

        it 'only renders the diffs for the path given' do
          expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
            expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
            meth.call(diffs)
          end

          diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })
        end
      end

      context 'when the path does not exist in the diff' do
        before do
          diff_for_path(old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb', merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET #branch_to' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
    end

    it 'fetches the commit if a user has access' do
      expect(Ability).to receive(:allowed?).with(user, :read_project, project) { true }

      get :branch_to,
          params: {
            namespace_id: fork_project.namespace,
            project_id: fork_project,
            target_project_id: project.id,
            ref: 'master'
          }

      expect(assigns(:commit)).not_to be_nil
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'does not load the commit when the user cannot read the project' do
      expect(Ability).to receive(:allowed?).with(user, :read_project, project) { false }

      get :branch_to,
          params: {
            namespace_id: fork_project.namespace,
            project_id: fork_project,
            target_project_id: project.id,
            ref: 'master'
          }

      expect(assigns(:commit)).to be_nil
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'no target_project_id provided' do
      before do
        project.add_maintainer(user)
      end

      it 'selects itself as a target project' do
        get :branch_to,
          params: {
          namespace_id: project.namespace,
          project_id: project,
          ref: 'master'
        }

        expect(assigns(:target_project)).to eq(project)
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'project is a fork' do
        it 'calls to project defaults to selects a correct target project' do
          get :branch_to,
            params: {
            namespace_id: fork_project.namespace,
            project_id: fork_project,
            ref: 'master'
          }

          expect(assigns(:target_project)).to eq(project)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST create' do
    let(:params) do
      {
        namespace_id: fork_project.namespace.to_param,
        project_id: fork_project,
        merge_request: {
          title: 'Test merge request',
          source_branch: 'remove-submodule',
          target_branch: 'master'
        }
      }
    end

    it 'creates merge request' do
      expect do
        post_request(params)
      end.to change { MergeRequest.count }.by(1)
    end

    context 'when the merge request is not created from the web ide' do
      it 'counter is not increased' do
        expect(Gitlab::UsageDataCounters::WebIdeCounter).not_to receive(:increment_merge_requests_count)

        post_request(params)
      end
    end

    context 'when the merge request is created from the web ide' do
      let(:nav_source) { { nav_source: 'webide' } }

      it 'counter is increased' do
        expect(Gitlab::UsageDataCounters::WebIdeCounter).to receive(:increment_merge_requests_count)

        post_request(params.merge(nav_source))
      end
    end

    def post_request(merge_request_params)
      post :create, params: merge_request_params
    end
  end
end
