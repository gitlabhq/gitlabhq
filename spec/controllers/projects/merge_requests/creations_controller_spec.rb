# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::CreationsController, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.first_owner }
  let(:fork_project) { create(:forked_project_with_submodules) }

  let(:base_params) do
    { project_id: fork_project, namespace_id: fork_project.namespace.to_param }
  end

  let(:get_diff_params) do
    base_params.merge(
      merge_request: {
        source_branch: 'remove-submodule',
        target_branch: 'master'
      }
    )
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
        base_params.merge(
          merge_request: {
            source_branch: 'master',
            target_branch: 'fix'
          }
        )
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
      end
    end

    context 'with tracking' do
      let(:base_params) do
        { project_id: project, namespace_id: project.namespace.to_param }
      end

      context 'when webide source' do
        it_behaves_like 'internal event tracking' do
          let(:event) { 'create_mr_web_ide' }

          subject { get :new, params: base_params.merge(nav_source: 'webide') }
        end
      end

      context 'when after push link' do
        it_behaves_like 'internal event tracking' do
          let(:event) { 'visit_after_push_link_or_create_mr_banner' }

          subject do
            get :new, params: base_params.merge(merge_request: { source_branch: 'feature' })
          end
        end
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
      create(:ci_pipeline, sha: fork_project.commit('remove-submodule').id, ref: 'remove-submodule', project: fork_project)
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
      expect(Ability).to receive(:allowed?).with(user, :create_merge_request_in, project) { true }.at_least(:once)

      get :branch_to, params: base_params.merge(target_project_id: project.id, ref: 'master')

      expect(assigns(:commit)).not_to be_nil
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'does not load the commit when the user cannot create_merge_request_in' do
      expect(Ability).to receive(:allowed?).with(user, :read_project, project) { true }
      expect(Ability).to receive(:allowed?).with(user, :create_merge_request_in, project) { false }.at_least(:once)

      get :branch_to, params: base_params.merge(target_project_id: project.id, ref: 'master')

      expect(assigns(:commit)).to be_nil
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'does not load the commit when the user cannot read the project' do
      expect(Ability).to receive(:allowed?).with(user, :read_project, project) { false }
      expect(Ability).to receive(:allowed?).with(user, :create_merge_request_in, project) { true }.at_least(:once)

      get :branch_to, params: base_params.merge(target_project_id: project.id, ref: 'master')

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
          get :branch_to, params: base_params.merge(ref: 'master')

          expect(assigns(:target_project)).to eq(project)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST create' do
    let(:params) do
      base_params.merge(
        merge_request: {
          title: 'Test merge request',
          source_branch: 'remove-submodule',
          target_branch: 'master'
        }
      )
    end

    it 'creates merge request' do
      expect do
        post_request(params)
      end.to change { MergeRequest.count }.by(1)
    end

    context 'when the merge request is not created from the web ide' do
      it 'counter is not increased' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        post_request(params)
      end
    end

    context 'when the merge request is created from the web ide' do
      let(:nav_source) { { nav_source: 'webide' } }

      let(:base_params) do
        { project_id: project, namespace_id: project.namespace.to_param }
      end

      let(:params) do
        base_params.merge(
          merge_request: {
            title: 'Test merge request',
            source_branch: 'remove-submodule',
            target_branch: 'master'
          }
        )
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'create_merge_request_from_web_ide' }

        subject { post_request(params.merge(nav_source)) }
      end
    end

    def post_request(merge_request_params)
      post :create, params: merge_request_params
    end
  end

  describe 'GET target_projects', feature_category: :code_review_workflow do
    it 'returns target projects JSON' do
      get :target_projects, params: { namespace_id: project.namespace.to_param, project_id: project }

      expect(json_response.size).to be(2)

      forked_project = json_response.detect { |project| project['id'] == fork_project.id }
      expect(forked_project).to have_key('id')
      expect(forked_project).to have_key('name')
      expect(forked_project).to have_key('full_path')
      expect(forked_project).to have_key('refs_url')
      expect(forked_project).to have_key('forked')
    end
  end
end
