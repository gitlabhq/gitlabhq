# frozen_string_literal: true

require 'spec_helper'

describe Projects::MergeRequestsController do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_with_conflicts) do
    create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start', source_project: project, merge_status: :unchecked) do |mr|
      mr.mark_as_unmergeable
    end
  end

  before do
    sign_in(user)
  end

  describe 'GET commit_change_content' do
    it 'renders commit_change_content template' do
      get :commit_change_content,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: 'html'

      expect(response).to render_template('_commit_change_content')
    end
  end

  describe "GET show" do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }

      get :show, params: params.merge(extra_params)
    end

    describe 'as html' do
      context 'when diff files were cleaned' do
        render_views

        it 'renders page when diff size is not persisted and diff_refs does not exist' do
          diff = merge_request.merge_request_diff

          diff.clean!
          diff.update!(real_size: nil,
                       start_commit_sha: nil,
                       base_commit_sha: nil)

          go(format: :html)

          expect(response).to be_success
        end
      end

      it "renders merge request page" do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        go(format: :html)

        expect(response).to be_success
      end

      context "that is invalid" do
        let(:merge_request) { create(:invalid_merge_request, target_project: project, source_project: project) }

        it "renders merge request page" do
          go(format: :html)

          expect(response).to be_success
        end
      end
    end

    context 'when user is setting notes filters' do
      let(:issuable) { merge_request }
      let(:issuable_parent) { project }
      let!(:discussion_note) { create(:discussion_note_on_merge_request, :system, noteable: issuable, project: project) }
      let!(:discussion_comment) { create(:discussion_note_on_merge_request, noteable: issuable, project: project) }

      it_behaves_like 'issuable notes filter'
    end

    describe 'as json' do
      before do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
      end

      context 'with basic serializer param' do
        it 'renders basic MR entity as json' do
          go(serializer: 'basic', format: :json)

          expect(response).to match_response_schema('entities/merge_request_basic')
        end
      end

      context 'with widget serializer param' do
        it 'renders widget MR entity as json' do
          go(serializer: 'widget', format: :json)

          expect(response).to match_response_schema('entities/merge_request_widget')
        end
      end

      context 'when no serialiser was passed' do
        it 'renders widget MR entity as json' do
          go(serializer: nil, format: :json)

          expect(response).to match_response_schema('entities/merge_request_widget')
        end
      end

      context "that is invalid" do
        let(:merge_request) { create(:invalid_merge_request, target_project: project, source_project: project) }

        it "renders merge request page" do
          go(format: :json)

          expect(response).to be_success
        end
      end
    end

    describe "as diff" do
      it "triggers workhorse to serve the request" do
        go(format: :diff)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-diff:")
      end
    end

    describe "as patch" do
      it 'triggers workhorse to serve the request' do
        go(format: :patch)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-format-patch:")
      end
    end
  end

  describe 'GET index' do
    let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    def get_merge_requests(page = nil)
      get :index,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            state: 'opened',
            page: page.to_param
          }
    end

    it_behaves_like "issuables list meta-data", :merge_request

    it_behaves_like 'set sort order from user preference' do
      let(:sorting_param) { 'updated_asc' }
    end

    context 'when page param' do
      let(:last_page) { project.merge_requests.page.total_pages }
      let!(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

      it 'redirects to last_page if page number is larger than number of pages' do
        get_merge_requests(last_page + 1)

        expect(response).to redirect_to(namespace_project_merge_requests_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
      end

      it 'redirects to specified page' do
        get_merge_requests(last_page)

        expect(assigns(:merge_requests).current_page).to eq(last_page)
        expect(response).to have_gitlab_http_status(200)
      end

      it 'does not redirect to external sites when provided a host field' do
        external_host = "www.example.com"
        get :index,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            state: 'opened',
            page: (last_page + 1).to_param,
            host: external_host
          }

        expect(response).to redirect_to(namespace_project_merge_requests_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
      end
    end

    context 'when filtering by opened state' do
      context 'with opened merge requests' do
        it 'lists those merge requests' do
          expect(merge_request).to be_persisted

          get_merge_requests

          expect(assigns(:merge_requests)).to include(merge_request)
        end
      end

      context 'with reopened merge requests' do
        before do
          merge_request.close!
          merge_request.reopen!
        end

        it 'lists those merge requests' do
          get_merge_requests

          expect(assigns(:merge_requests)).to include(merge_request)
        end
      end
    end
  end

  describe 'PUT update' do
    def update_merge_request(mr_params, additional_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid,
        merge_request: mr_params
      }.merge(additional_params)

      put :update, params: params
    end

    context 'changing the assignee' do
      it 'limits the attributes exposed on the assignee' do
        assignee = create(:user)
        project.add_developer(assignee)

        update_merge_request({ assignee_ids: [assignee.id] }, format: :json)

        body = JSON.parse(response.body)

        expect(body['assignees']).to all(include(*%w(name username avatar_url id state web_url)))
      end
    end

    context 'when user does not have access to update issue' do
      before do
        reporter = create(:user)
        project.add_reporter(reporter)
        sign_in(reporter)
      end

      it 'responds with 404' do
        update_merge_request(title: 'New title')

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'there is no source project' do
      let(:project) { create(:project, :repository) }
      let(:forked_project) { fork_project_with_submodules(project) }
      let!(:merge_request) { create(:merge_request, source_project: forked_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

      before do
        forked_project.destroy
      end

      it 'closes MR without errors' do
        update_merge_request(state_event: 'close')

        expect(response).to redirect_to([merge_request.target_project.namespace.becomes(Namespace), merge_request.target_project, merge_request])
        expect(merge_request.reload.closed?).to be_truthy
      end

      it 'allows editing of a closed merge request' do
        merge_request.close!

        update_merge_request(title: 'New title')

        expect(response).to redirect_to([merge_request.target_project.namespace.becomes(Namespace), merge_request.target_project, merge_request])
        expect(merge_request.reload.title).to eq 'New title'
      end

      it 'does not allow to update target branch closed merge request' do
        merge_request.close!

        update_merge_request(target_branch: 'new_branch')

        expect { merge_request.reload.target_branch }.not_to change { merge_request.target_branch }
      end

      it_behaves_like 'update invalid issuable', MergeRequest
    end

    context 'two merge requests with the same source branch' do
      it 'does not allow a closed merge request to be reopened if another one is open' do
        merge_request.close!
        create(:merge_request, source_project: merge_request.source_project, source_branch: merge_request.source_branch)

        update_merge_request(state_event: 'reopen')

        errors = assigns[:merge_request].errors

        expect(errors[:validate_branches]).to include(/Another open merge request already exists for this source branch/)
        expect(merge_request.reload).to be_closed
      end
    end
  end

  describe 'POST merge' do
    let(:base_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid,
        squash: false,
        format: 'json'
      }
    end

    context 'when user cannot access' do
      let(:user) { create(:user) }

      before do
        project.add_reporter(user)
        post :merge, params: base_params, xhr: true
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the merge request is not mergeable' do
      before do
        merge_request.update(title: "WIP: #{merge_request.title}")

        post :merge, params: base_params
      end

      it 'returns :failed' do
        expect(json_response).to eq('status' => 'failed')
      end
    end

    context 'when the sha parameter does not match the source SHA' do
      before do
        post :merge, params: base_params.merge(sha: 'foo')
      end

      it 'returns :sha_mismatch' do
        expect(json_response).to eq('status' => 'sha_mismatch')
      end
    end

    context 'when the sha parameter matches the source SHA' do
      def merge_with_sha(params = {})
        post_params = base_params.merge(sha: merge_request.diff_head_sha).merge(params)
        post :merge, params: post_params, as: :json
      end

      it 'returns :success' do
        merge_with_sha

        expect(json_response).to eq('status' => 'success')
      end

      it 'starts the merge immediately with permitted params' do
        expect(MergeWorker).to receive(:perform_async).with(merge_request.id, anything, { 'squash' => false })

        merge_with_sha
      end

      context 'when squash is passed as 1' do
        it 'updates the squash attribute on the MR to true' do
          merge_request.update(squash: false)
          merge_with_sha(squash: '1')

          expect(merge_request.reload.squash).to be_truthy
        end
      end

      context 'when squash is passed as 0' do
        it 'updates the squash attribute on the MR to false' do
          merge_request.update(squash: true)
          merge_with_sha(squash: '0')

          expect(merge_request.reload.squash).to be_falsey
        end
      end

      context 'when a squash commit message is passed' do
        let(:message) { 'My custom squash commit message' }

        it 'passes the same message to SquashService' do
          params = { squash: '1', squash_commit_message: message }

          expect_next_instance_of(MergeRequests::SquashService, project, user, params.merge(merge_request: merge_request)) do |squash_service|
            expect(squash_service).to receive(:execute).and_return({
              status: :success,
              squash_sha: SecureRandom.hex(20)
            })
          end

          merge_with_sha(params)
        end
      end

      context 'when merge when pipeline succeeds option is passed' do
        let!(:head_pipeline) do
          create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch, head_pipeline_of: merge_request)
        end

        def merge_when_pipeline_succeeds
          post :merge, params: base_params.merge(sha: merge_request.diff_head_sha, merge_when_pipeline_succeeds: '1')
        end

        it 'returns :merge_when_pipeline_succeeds' do
          merge_when_pipeline_succeeds

          expect(json_response).to eq('status' => 'merge_when_pipeline_succeeds')
        end

        it 'sets the MR to merge when the pipeline succeeds' do
          service = double(:merge_when_pipeline_succeeds_service)
          allow(service).to receive(:available_for?) { true }

          expect(AutoMerge::MergeWhenPipelineSucceedsService)
            .to receive(:new).with(project, anything, anything)
            .and_return(service)
          expect(service).to receive(:execute).with(merge_request)

          merge_when_pipeline_succeeds
        end

        context 'when project.only_allow_merge_if_pipeline_succeeds? is true' do
          before do
            project.update_column(:only_allow_merge_if_pipeline_succeeds, true)
          end

          context 'and head pipeline is not the current one' do
            before do
              head_pipeline.update(sha: 'not_current_sha')
            end

            it 'returns :failed' do
              merge_when_pipeline_succeeds

              expect(json_response).to eq('status' => 'failed')
            end
          end

          it 'returns :merge_when_pipeline_succeeds' do
            merge_when_pipeline_succeeds

            expect(json_response).to eq('status' => 'merge_when_pipeline_succeeds')
          end
        end

        context 'when auto merge has not been enabled yet' do
          it 'calls AutoMergeService#execute' do
            expect_next_instance_of(AutoMergeService) do |service|
              expect(service).to receive(:execute).with(merge_request, 'merge_when_pipeline_succeeds')
            end

            merge_when_pipeline_succeeds
          end
        end

        context 'when auto merge has already been enabled' do
          before do
            merge_request.update!(auto_merge_enabled: true, merge_user: user)
          end

          it 'calls AutoMergeService#update' do
            expect_next_instance_of(AutoMergeService) do |service|
              expect(service).to receive(:update).with(merge_request)
            end

            merge_when_pipeline_succeeds
          end
        end
      end

      describe 'only_allow_merge_if_all_discussions_are_resolved? setting' do
        let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project, author: user) }

        context 'when enabled' do
          before do
            project.update_column(:only_allow_merge_if_all_discussions_are_resolved, true)
          end

          context 'with unresolved discussion' do
            before do
              expect(merge_request).not_to be_discussions_resolved
            end

            it 'returns :failed' do
              merge_with_sha

              expect(json_response).to eq('status' => 'failed')
            end
          end

          context 'with all discussions resolved' do
            before do
              merge_request.discussions.each { |d| d.resolve!(user) }
              expect(merge_request).to be_discussions_resolved
            end

            it 'returns :success' do
              merge_with_sha

              expect(json_response).to eq('status' => 'success')
            end
          end
        end

        context 'when disabled' do
          before do
            project.update_column(:only_allow_merge_if_all_discussions_are_resolved, false)
          end

          context 'with unresolved discussion' do
            before do
              expect(merge_request).not_to be_discussions_resolved
            end

            it 'returns :success' do
              merge_with_sha

              expect(json_response).to eq('status' => 'success')
            end
          end

          context 'with all discussions resolved' do
            before do
              merge_request.discussions.each { |d| d.resolve!(user) }
              expect(merge_request).to be_discussions_resolved
            end

            it 'returns :success' do
              merge_with_sha

              expect(json_response).to eq('status' => 'success')
            end
          end
        end
      end
    end
  end

  describe "DELETE destroy" do
    let(:user) { create(:user) }

    it "denies access to users unless they're admin or project owner" do
      delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }

      expect(response).to have_gitlab_http_status(404)
    end

    context "when the user is owner" do
      let(:owner)     { create(:user) }
      let(:namespace) { create(:namespace, owner: owner) }
      let(:project)   { create(:project, :repository, namespace: namespace) }

      before do
        sign_in owner
      end

      it "deletes the merge request" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }

        expect(response).to have_gitlab_http_status(302)
        expect(controller).to set_flash[:notice].to(/The merge request was successfully deleted\./)
      end

      it 'delegates the update of the todos count cache to TodoService' do
        expect_any_instance_of(TodoService).to receive(:destroy_target).with(merge_request).once

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }
      end
    end
  end

  describe 'GET commits' do
    def go(format: 'html')
      get :commits,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: merge_request.iid
          },
          format: format
    end

    it 'renders the commits template to a string' do
      go format: 'json'

      expect(response).to render_template('projects/merge_requests/_commits')
      expect(json_response).to have_key('html')
    end
  end

  describe 'GET pipelines' do
    before do
      create(:ci_pipeline, project: merge_request.source_project,
                           ref: merge_request.source_branch,
                           sha: merge_request.diff_head_sha)

      get :pipelines,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: merge_request.iid
          },
          format: :json
    end

    it 'responds with serialized pipelines' do
      expect(json_response['pipelines']).not_to be_empty
      expect(json_response['count']['all']).to eq 1
      expect(response).to include_pagination_headers
    end
  end

  describe 'GET test_reports' do
    subject do
      get :test_reports,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: merge_request.iid
          },
          format: :json
    end

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:compare_test_reports).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { summary: 1 } } }

      it 'does not send polling interval' do
        expect(Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'summary' => 1 })
      end
    end

    context 'when user created corrupted test reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse test reports' } }

      it 'does not send polling interval' do
        expect(Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse test reports' })
      end
    end

    context 'when something went wrong on our system' do
      let(:comparison_status) { {} }

      it 'does not send polling interval' do
        expect(Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 500 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(json_response).to eq({ 'status_reason' => 'Unknown error' })
      end
    end
  end

  describe 'POST remove_wip' do
    before do
      merge_request.title = merge_request.wip_title
      merge_request.save

      post :remove_wip,
        params: {
          format: :json,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid
        },
        xhr: true
    end

    it 'removes the wip status' do
      expect(merge_request.reload.title).to eq(merge_request.wipless_title)
    end

    it 'renders MergeRequest as JSON' do
      expect(json_response.keys).to include('id', 'iid', 'description')
    end
  end

  describe 'POST cancel_auto_merge' do
    subject do
      post :cancel_auto_merge,
        params: {
          format: :json,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid
        },
        xhr: true
    end

    it 'calls AutoMergeService' do
      auto_merge_service = double

      allow(AutoMergeService)
        .to receive(:new)
        .and_return(auto_merge_service)

      allow(auto_merge_service).to receive(:available_strategies).with(merge_request)
      expect(auto_merge_service).to receive(:cancel).with(merge_request)

      subject
    end

    it { is_expected.to have_gitlab_http_status(:success) }

    it 'renders MergeRequest as JSON' do
      subject

      expect(json_response.keys).to include('id', 'iid', 'description')
    end
  end

  describe 'POST assign_related_issues' do
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project) }

    def post_assign_issues
      merge_request.update!(description: "Closes #{issue1.to_reference} and #{issue2.to_reference}",
                            author: user,
                            source_branch: 'feature',
                            target_branch: 'master')

      post :assign_related_issues,
           params: {
             namespace_id: project.namespace.to_param,
             project_id: project,
             id: merge_request.iid
           }
    end

    it 'shows a flash message on success' do
      post_assign_issues

      expect(flash[:notice]).to eq '2 issues have been assigned to you'
    end

    it 'correctly pluralizes flash message on success' do
      issue2.assignees = [user]

      post_assign_issues

      expect(flash[:notice]).to eq '1 issue has been assigned to you'
    end

    it 'calls MergeRequests::AssignIssuesService' do
      expect(MergeRequests::AssignIssuesService).to receive(:new)
        .with(project, user, merge_request: merge_request)
        .and_return(double(execute: { count: 1 }))

      post_assign_issues
    end

    it 'is skipped when not signed in' do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      sign_out(:user)

      expect(MergeRequests::AssignIssuesService).not_to receive(:new)

      post_assign_issues
    end
  end

  describe 'GET ci_environments_status' do
    context 'the environment is from a forked project' do
      let(:forked)      { fork_project(project, user, repository: true) }
      let(:sha)         { forked.commit.sha }
      let(:environment) { create(:environment, project: forked) }
      let(:pipeline)    { create(:ci_pipeline, sha: sha, project: forked) }
      let(:build)       { create(:ci_build, pipeline: pipeline) }
      let!(:deployment) { create(:deployment, :succeed, environment: environment, sha: sha, ref: 'master', deployable: build) }

      let(:merge_request) do
        create(:merge_request, source_project: forked, target_project: project, target_branch: 'master', head_pipeline: pipeline)
      end

      it 'links to the environment on that project' do
        get_ci_environments_status

        expect(json_response.first['url']).to match /#{forked.full_path}/
      end

      context "when environment_target is 'merge_commit'" do
        it 'returns nothing' do
          get_ci_environments_status(environment_target: 'merge_commit')

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_empty
        end

        context 'when is merged' do
          let(:source_environment)  { create(:environment, project: project) }
          let(:merge_commit_sha)    { project.repository.merge(user, forked.commit.id, merge_request, "merged in test") }
          let(:post_merge_pipeline) { create(:ci_pipeline, sha: merge_commit_sha, project: project) }
          let(:post_merge_build)    { create(:ci_build, pipeline: post_merge_pipeline) }
          let!(:source_deployment)  { create(:deployment, :succeed, environment: source_environment, sha: merge_commit_sha, ref: 'master', deployable: post_merge_build) }

          before do
            merge_request.update!(merge_commit_sha: merge_commit_sha)
            merge_request.mark_as_merged!
          end

          it 'returns the environment on the source project' do
            get_ci_environments_status(environment_target: 'merge_commit')

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.first['url']).to match /#{project.full_path}/
          end
        end
      end

      # we're trying to reduce the overall number of queries for this method.
      # set a hard limit for now. https://gitlab.com/gitlab-org/gitlab-ce/issues/52287
      it 'keeps queries in check' do
        control_count = ActiveRecord::QueryRecorder.new { get_ci_environments_status }.count

        expect(control_count).to be <= 137
      end

      it 'has no N+1 SQL issues for environments', :request_store, retry: 0 do
        # First run to insert test data from lets, which does take up some 30 queries
        get_ci_environments_status

        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { get_ci_environments_status }.count

        environment2 = create(:environment, project: forked)
        create(:deployment, :succeed, environment: environment2, sha: sha, ref: 'master', deployable: build)

        # TODO address the last 11 queries
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63952 (5 queries)
        # And https://gitlab.com/gitlab-org/gitlab-ce/issues/64105 (6 queries)
        leeway = 11
        expect { get_ci_environments_status }.not_to exceed_all_query_limit(control_count + leeway)
      end
    end

    context 'when a merge request has multiple environments with deployments' do
      let(:sha) { merge_request.diff_head_sha }
      let(:ref) { merge_request.source_branch }

      let!(:build) { create(:ci_build, pipeline: pipeline) }
      let!(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
      let!(:environment) { create(:environment, name: 'env_a', project: project) }
      let!(:another_environment) { create(:environment, name: 'env_b', project: project) }

      before do
        merge_request.update_head_pipeline

        create(:deployment, :succeed, environment: environment, sha: sha, ref: ref, deployable: build)
        create(:deployment, :succeed, environment: another_environment, sha: sha, ref: ref, deployable: build)
      end

      it 'exposes multiple environment statuses' do
        get_ci_environments_status

        expect(json_response.count).to eq 2
      end

      context 'when route map is not present in the project' do
        it 'does not have N+1 Gitaly requests for environments', :request_store do
          expect(merge_request).to be_present

          expect { get_ci_environments_status }
            .not_to change { Gitlab::GitalyClient.get_request_count }
        end
      end

      context 'when there is route map present in a project' do
        before do
          allow_any_instance_of(EnvironmentStatus)
            .to receive(:has_route_map?)
            .and_return(true)
        end

        it 'does not have N+1 Gitaly requests for diff files', :request_store do
          expect(merge_request.merge_request_diff.merge_request_diff_files).to be_many

          expect { get_ci_environments_status }
            .not_to change { Gitlab::GitalyClient.get_request_count }
        end
      end
    end

    def get_ci_environments_status(extra_params = {})
      params = {
        namespace_id: merge_request.project.namespace.to_param,
        project_id: merge_request.project,
        id: merge_request.iid,
        format: 'json'
      }

      get :ci_environments_status, params: params.merge(extra_params)
    end
  end

  describe 'GET pipeline_status.json' do
    context 'when head_pipeline exists' do
      let!(:pipeline) do
        create(:ci_pipeline, project: merge_request.source_project,
                             ref: merge_request.source_branch,
                             sha: merge_request.diff_head_sha,
                             head_pipeline_of: merge_request)
      end

      let(:status) { pipeline.detailed_status(double('user')) }

      before do
        get_pipeline_status
      end

      it 'return a detailed head_pipeline status in json' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['text']).to eq status.text
        expect(json_response['label']).to eq status.label
        expect(json_response['icon']).to eq status.icon
        expect(json_response['favicon']).to match_asset_path "/assets/ci_favicons/#{status.favicon}.png"
      end
    end

    context 'when head_pipeline does not exist' do
      before do
        get_pipeline_status
      end

      it 'return empty' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    def get_pipeline_status
      get :pipeline_status, params: {
                              namespace_id: project.namespace,
                              project_id: project,
                              id: merge_request.iid
                            },
                            format: :json
    end
  end

  describe 'POST #rebase' do
    let(:viewer) { user }

    def post_rebase
      post :rebase, params: { namespace_id: project.namespace, project_id: project, id: merge_request }
    end

    def expect_rebase_worker_for(user)
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, user.id)
    end

    context 'successfully' do
      it 'enqeues a RebaseWorker' do
        expect_rebase_worker_for(viewer)

        post_rebase

        expect(response.status).to eq(200)
      end
    end

    context 'with a forked project' do
      let(:forked_project) { fork_project(project, fork_owner, repository: true) }
      let(:fork_owner) { create(:user) }

      before do
        project.add_developer(fork_owner)

        merge_request.update!(source_project: forked_project)
        forked_project.add_reporter(user)
      end

      context 'user cannot push to source branch' do
        it 'returns 404' do
          expect_rebase_worker_for(viewer).never

          post_rebase

          expect(response.status).to eq(404)
        end
      end

      context 'user can push to source branch' do
        before do
          project.add_reporter(fork_owner)

          sign_in(fork_owner)
        end

        it 'returns 200' do
          expect_rebase_worker_for(fork_owner)

          post_rebase

          expect(response.status).to eq(200)
        end
      end
    end
  end

  describe 'GET discussions' do
    context 'when authenticated' do
      before do
        project.add_developer(user)
        sign_in(user)

        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
      end

      it 'returns 200' do
        get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }

        expect(response.status).to eq(200)
      end

      context 'highlight preloading' do
        context 'with commit diff notes' do
          let!(:commit_diff_note) do
            create(:diff_note_on_commit, project: merge_request.project)
          end

          it 'preloads notes diffs highlights' do
            expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
              note_diff_file = commit_diff_note.note_diff_file

              expect(collection).to receive(:load_highlight).with([note_diff_file.id]).and_call_original
              expect(collection).to receive(:find_by_id).with(note_diff_file.id).and_call_original
            end

            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }
          end
        end

        context 'with diff notes' do
          let!(:diff_note) do
            create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project)
          end

          it 'preloads notes diffs highlights' do
            expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
              note_diff_file = diff_note.note_diff_file

              expect(collection).to receive(:load_highlight).with([note_diff_file.id]).and_call_original
              expect(collection).to receive(:find_by_id).with(note_diff_file.id).and_call_original
            end

            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }
          end

          it 'does not preload highlights when diff note is resolved' do
            Notes::ResolveService.new(diff_note.project, user).execute(diff_note)

            expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
              note_diff_file = diff_note.note_diff_file

              expect(collection).to receive(:load_highlight).with([]).and_call_original
              expect(collection).to receive(:find_by_id).with(note_diff_file.id).and_call_original
            end

            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }
          end
        end
      end
    end
  end

  describe 'GET edit' do
    it 'responds successfully' do
      get :edit, params: { namespace_id: project.namespace, project_id: project, id: merge_request }

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'assigns the noteable to make sure autocompletes work' do
      get :edit, params: { namespace_id: project.namespace, project_id: project, id: merge_request }

      expect(assigns(:noteable)).not_to be_nil
    end
  end
end
