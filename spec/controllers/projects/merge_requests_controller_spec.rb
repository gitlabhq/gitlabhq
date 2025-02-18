# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include Gitlab::Routing
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be_with_reload(:project_public_with_private_builds) { create(:project, :repository, :public, :builds_private) }

  let(:user) { project.first_owner }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: merge_request_source_project, allow_collaboration: false) }
  let(:merge_request_source_project) { project }

  before do
    sign_in(user)
  end

  shared_examples 'a 400 response' do
    it 'does not send polling interval' do
      expect(Gitlab::PollingInterval).not_to receive(:set_header)

      subject
    end

    it 'returns 400 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns an error string' do
      subject

      expect(json_response['status_reason']).to eq error_string
      expect(json_response['errors']).to match_array [error_string]
    end
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

    context 'with view param' do
      before do
        go(view: 'parallel')
      end

      it 'saves the preferred diff view in a cookie' do
        expect(response.cookies['diff_view']).to eq('parallel')
      end
    end

    context 'when merge request is unchecked' do
      before do
        merge_request.mark_as_unchecked!
      end

      it 'checks mergeability asynchronously' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService) do |service|
          expect(service).not_to receive(:execute)
          expect(service).to receive(:async_execute)
        end

        go
      end
    end

    context 'when the merge request has auto merge enabled' do
      let(:merge_request) { create(:merge_request_with_diffs, :merge_when_checks_pass, target_project: project, source_project: merge_request_source_project, allow_collaboration: false) }

      context 'when the merge request is mergeable' do
        let(:pipeline) { create(:ci_pipeline, :success) }

        before do
          merge_request.update_attribute(:head_pipeline_id, pipeline.id)
        end

        it 'calls the auto merge process worker async' do
          expect { go }.to publish_event(MergeRequests::MergeableEvent)
            .with(merge_request_id: merge_request.id)
        end

        context 'when process_auto_merge_on_load is off' do
          before do
            stub_feature_flags(process_auto_merge_on_load: false)
          end

          it 'does not call the auto merge process worker' do
            expect { go }.not_to publish_event(MergeRequests::MergeableEvent)
          end
        end
      end

      context 'when the merge request is not mergeable' do
        it 'does not call the auto merge process worker' do
          merge_request.update!(title: "Draft: #{merge_request.title}")
          expect { go }.not_to publish_event(MergeRequests::MergeableEvent)
        end
      end
    end

    describe 'as html' do
      it 'sets the endpoint_metadata_url' do
        go

        expect(assigns["endpoint_metadata_url"]).to eq(
          diffs_metadata_project_json_merge_request_path(
            project,
            merge_request,
            'json',
            diff_head: true,
            view: 'inline',
            w: '0'))
      end

      context 'when merge_head diff is present' do
        before do
          create(:merge_request_diff, :merge_head, merge_request: merge_request)
        end

        it 'sets the endpoint_diff_batch_url with ck' do
          go

          expect(assigns["endpoint_diff_batch_url"]).to eq(
            diffs_batch_project_json_merge_request_path(
              project,
              merge_request,
              'json',
              diff_head: true,
              view: 'inline',
              w: '0',
              page: '0',
              per_page: '5',
              ck: merge_request.merge_head_diff.patch_id_sha))
        end

        it 'sets diffs_batch_cache_key' do
          go

          expect(assigns['diffs_batch_cache_key']).to eq(merge_request.merge_head_diff.patch_id_sha)
        end

        context 'when diffs_batch_cache_with_max_age feature flag is disabled' do
          before do
            stub_feature_flags(diffs_batch_cache_with_max_age: false)
          end

          it 'sets the endpoint_diff_batch_url without ck param' do
            go

            expect(assigns['endpoint_diff_batch_url']).to eq(
              diffs_batch_project_json_merge_request_path(
                project,
                merge_request,
                'json',
                diff_head: true,
                view: 'inline',
                w: '0',
                page: '0',
                per_page: '5'))
          end

          it 'does not set diffs_batch_cache_key' do
            go

            expect(assigns['diffs_batch_cache_key']).to be_nil
          end
        end
      end

      context 'when diff files were cleaned' do
        render_views

        it 'renders page when diff size is not persisted and diff_refs does not exist' do
          diff = merge_request.merge_request_diff

          diff.clean!
          diff.update!(real_size: nil, start_commit_sha: nil, base_commit_sha: nil)

          go(format: :html)

          expect(response).to be_successful
        end
      end

      context 'when diff is missing' do
        render_views

        it 'renders merge request page' do
          merge_request.merge_request_diff.destroy!

          go(format: :html)

          expect(response).to be_successful
        end
      end

      it "renders merge request page" do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        go(format: :html)

        expect(response).to be_successful
      end

      it 'logs the view with Gitlab::Search::RecentMergeRequests' do
        recent_merge_requests_double = instance_double(::Gitlab::Search::RecentMergeRequests, log_view: nil)
        expect(::Gitlab::Search::RecentMergeRequests).to receive(:new).with(user: user).and_return(recent_merge_requests_double)

        go(format: :html)

        expect(response).to be_successful
        expect(recent_merge_requests_double).to have_received(:log_view).with(merge_request)
      end

      context "that is invalid" do
        let(:merge_request) { create(:invalid_merge_request, target_project: project, source_project: project) }

        it "renders merge request page" do
          go(format: :html)

          expect(response).to be_successful
        end
      end

      context 'when project has moved' do
        let(:new_project) { create(:project) }

        before do
          project.route.destroy!
          new_project.redirect_routes.create!(path: project.full_path)
          new_project.add_developer(user)
        end

        it 'redirects from an old merge request correctly' do
          get :show, params: {
            namespace_id: project.namespace,
            project_id: project,
            id: merge_request
          }

          expect(response).to redirect_to(project_merge_request_path(new_project, merge_request))
          expect(response).to have_gitlab_http_status(:moved_permanently)
        end

        it 'redirects from an old merge request commits correctly' do
          get :commits, params: {
            namespace_id: project.namespace,
            project_id: project,
            id: merge_request
          }

          expect(response).to redirect_to(commits_project_merge_request_path(new_project, merge_request))
          expect(response).to have_gitlab_http_status(:moved_permanently)
        end
      end

      context 'when has linked file' do
        let(:file) { merge_request.merge_request_diff.diffs.diff_files.first }
        let(:file_hash) { file.file_hash }

        it 'adds linked file url' do
          go(file: file_hash)

          expect(assigns['linked_file_url']).to eq(
            diff_by_file_hash_namespace_project_merge_request_path(
              format: 'json',
              id: merge_request.iid,
              namespace_id: project.namespace.to_param,
              project_id: project.path,
              file_hash: file_hash,
              diff_head: true
            ))
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

          expect(response).to be_successful
        end
      end
    end

    describe "as diff" do
      it "triggers workhorse to serve the request" do
        go(format: :diff)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-diff:")
      end

      context 'when there is no diff' do
        it 'renders 404' do
          merge_request.merge_request_diff.destroy!

          go(format: :diff)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe "as patch" do
      it 'triggers workhorse to serve the request' do
        go(format: :patch)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-format-patch:")
      end

      context 'when there is no diff' do
        it 'renders 404' do
          merge_request.merge_request_diff.destroy!

          go(format: :patch)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET index' do
    let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    def get_merge_requests(page = nil)
      get :index, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        state: 'opened',
        page: page.to_param
      }
    end

    it 'renders merge requests index template' do
      get_merge_requests

      expect(response).to render_template('projects/merge_requests/index')
    end

    context 'when vue_merge_request_list is disabled' do
      before do
        stub_feature_flags(vue_merge_request_list: false)
      end

      context 'when the test is flaky', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450217' do
        it_behaves_like "issuables list meta-data", :merge_request
      end

      it_behaves_like 'set sort order from user preference' do
        let(:sorting_param) { 'updated_asc' }
      end

      context 'when page param' do
        let(:last_page) { project.merge_requests.page.total_pages }
        let!(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

        it 'redirects to last_page if page number is larger than number of pages' do
          get_merge_requests(last_page + 1)

          expect(response).to redirect_to(project_merge_requests_path(project, page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
        end

        it 'redirects to specified page' do
          get_merge_requests(last_page)

          expect(assigns(:merge_requests).current_page).to eq(last_page)
          expect(response).to have_gitlab_http_status(:ok)
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

          expect(response).to redirect_to(project_merge_requests_path(project, page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
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
  end

  describe 'PUT update' do
    def update_merge_request(mr_params, additional_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid,
        merge_request: mr_params,
        serializer: 'basic'
      }.merge(additional_params)

      put :update, params: params
    end

    context 'changing the assignee' do
      it 'limits the attributes exposed on the assignee' do
        assignee = create(:user)
        project.add_developer(assignee)

        update_merge_request({ assignee_ids: [assignee.id] }, format: :json)

        expect(json_response['assignees']).to all(include(*%w[name username avatar_url id state web_url]))
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'there is no source project' do
      let(:forked_project) { fork_project_with_submodules(project) }
      let!(:merge_request) { create(:merge_request, source_project: forked_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

      before do
        forked_project.destroy!
      end

      it 'closes MR without errors' do
        update_merge_request(state_event: 'close')

        expect(response).to redirect_to([merge_request.target_project, merge_request])
        expect(merge_request.reload.closed?).to be_truthy
      end

      it 'allows editing of a closed merge request' do
        merge_request.close!

        update_merge_request(title: 'New title')

        expect(response).to redirect_to([merge_request.target_project, merge_request])
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
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the merge request is not mergeable' do
      before do
        merge_request.update!(title: "Draft: #{merge_request.title}")

        post :merge, params: base_params
      end

      it 'returns :failed' do
        expect(json_response).to eq('status' => 'failed')
      end

      context 'for logging' do
        let(:expected_params) { { merge_action_status: 'failed' } }
        let(:subject_proc) { proc { subject } }

        subject { post :merge, params: base_params }

        it_behaves_like 'storing arguments in the application context'
        it_behaves_like 'not executing any extra queries for the application context'
      end
    end

    context 'when the sha parameter does not match the source SHA' do
      before do
        post :merge, params: base_params.merge(sha: 'foo')
      end

      it 'returns :sha_mismatch' do
        expect(json_response).to eq('status' => 'sha_mismatch')
      end

      context 'for logging' do
        let(:expected_params) { { merge_action_status: 'sha_mismatch' } }
        let(:subject_proc) { proc { subject } }

        subject { post :merge, params: base_params.merge(sha: 'foo') }

        it_behaves_like 'storing arguments in the application context'
        it_behaves_like 'not executing any extra queries for the application context'
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
        allow(MergeWorker).to receive(:with_status).and_return(MergeWorker)
        expect(MergeWorker).to receive(:perform_async).with(merge_request.id, anything, { 'sha' => merge_request.diff_head_sha })

        merge_with_sha
      end

      context 'for logging' do
        let(:expected_params) { { merge_action_status: 'success' } }
        let(:subject_proc) { proc { subject } }

        subject { merge_with_sha }

        it_behaves_like 'storing arguments in the application context'
        it_behaves_like 'not executing any extra queries for the application context'
      end

      context 'when squash is passed as 1' do
        it 'updates the squash attribute on the MR to true' do
          merge_request.update!(squash: false)
          merge_with_sha(squash: '1')

          expect(merge_request.reload.squash_on_merge?).to be_truthy
        end
      end

      context 'when squash is passed as 0' do
        it 'updates the squash attribute on the MR to false' do
          merge_request.update!(squash: true)
          merge_with_sha(squash: '0')

          expect(merge_request.reload.squash_on_merge?).to be_falsey
        end
      end

      context 'when a squash commit message is passed' do
        let(:message) { 'My custom squash commit message' }

        it 'passes the same message to SquashService', :sidekiq_inline do
          expect_next_instance_of(MergeRequests::SquashService,
            merge_request: merge_request,
            current_user: user,
            commit_message: message) do |squash_service|
            expect(squash_service).to receive(:execute).and_return({
              status: :success,
              squash_sha: SecureRandom.hex(20)
            })
          end

          merge_with_sha(squash: '1', squash_commit_message: message, sha: merge_request.diff_head_sha)
        end
      end

      context 'when merge when pipeline succeeds option is passed' do
        let!(:head_pipeline) do
          create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch, head_pipeline_of: merge_request)
        end

        def set_auto_merge
          post :merge, params: base_params.merge(sha: merge_request.diff_head_sha, merge_when_pipeline_succeeds: '1')
        end

        it_behaves_like 'api merge with auto merge' do
          let(:service_class) { AutoMerge::MergeWhenChecksPassService }
          let(:status) { 'merge_when_checks_pass' }
          let(:not_current_pipeline_status) { 'merge_when_checks_pass' }
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

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context "when the user is owner" do
      let_it_be(:owner)     { create(:user) }
      let_it_be(:namespace) { create(:namespace, owner: owner) }
      let_it_be(:project)   { create(:project, :repository, namespace: namespace) }

      before do
        sign_in owner
      end

      it "deletes the merge request" do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid, destroy_confirm: true }

        expect(response).to have_gitlab_http_status(:see_other)
        expect(controller).to set_flash[:notice].to(/The merge request was successfully deleted\./)
      end

      it "prevents deletion if destroy_confirm is not set" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }

        expect(response).to have_gitlab_http_status(:found)
        expect(controller).to set_flash[:notice].to('Destroy confirmation not provided for merge request')
      end

      it "prevents deletion in JSON format if destroy_confirm is not set" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid, format: 'json' }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'errors' => 'Destroy confirmation not provided for merge request' })
      end
    end
  end

  describe 'GET commits' do
    def go(page: nil, per_page: 1, format: 'html')
      get :commits, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        page: page,
        per_page: per_page
      }, format: format
    end

    it 'renders the commits template to a string' do
      go format: 'json'

      expect(response).to render_template('projects/merge_requests/_commits')
      expect(json_response).to have_key('html')
      expect(json_response).to have_key('next_page')
      expect(json_response['next_page']).to eq(2)
    end

    describe 'pagination' do
      where(:page, :next_page) do
        1 | 2
        2 | 3
        3 | nil
      end

      with_them do
        it "renders the commits for page #{params[:page]}" do
          go format: 'json', page: page, per_page: 10

          expect(response).to render_template('projects/merge_requests/_commits')
          expect(json_response).to have_key('html')
          expect(json_response).to have_key('next_page')
          expect(json_response['next_page']).to eq(next_page)
        end
      end
    end
  end

  describe 'GET pipelines' do
    before do
      create(
        :ci_pipeline,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha
      )

      get :pipelines, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }, format: :json
    end

    context 'with "enabled" builds on a public project' do
      let(:project) { create(:project, :repository, :public) }

      context 'for a project owner' do
        it 'responds with serialized pipelines' do
          expect(json_response['pipelines']).to be_present
          expect(json_response['count']['all']).to eq(1)
          expect(response).to include_pagination_headers
        end
      end

      context 'for an unassociated user' do
        let(:user) { create :user }

        it 'responds with no pipelines' do
          expect(json_response['pipelines']).to be_present
          expect(json_response['count']['all']).to eq(1)
          expect(response).to include_pagination_headers
        end
      end
    end

    context 'with private builds on a public project' do
      let(:project) { project_public_with_private_builds }

      context 'for a project owner' do
        it 'responds with serialized pipelines' do
          expect(json_response['pipelines']).to be_present
          expect(json_response['count']['all']).to eq(1)
          expect(response).to include_pagination_headers
        end
      end

      context 'for an unassociated user' do
        let(:user) { create :user }

        it 'responds with no pipelines' do
          expect(json_response['pipelines']).to be_empty
          expect(json_response['count']['all']).to eq(0)
          expect(response).to include_pagination_headers
        end
      end

      context 'from a project fork' do
        let(:fork_user)      { create :user }
        let(:forked_project) { fork_project(project, fork_user, repository: true) } # Forked project carries over :builds_private
        let(:merge_request)  { create(:merge_request_with_diffs, target_project: project, source_project: forked_project) }

        context 'with private builds' do
          context 'for the target project member' do
            it 'does not respond with serialized pipelines' do
              expect(json_response['pipelines']).to be_empty
              expect(json_response['count']['all']).to eq(0)
              expect(response).to include_pagination_headers
            end
          end

          context 'for the source project member' do
            let(:user) { fork_user }

            it 'responds with serialized pipelines' do
              expect(json_response['pipelines']).to be_present
              expect(json_response['count']['all']).to eq(1)
              expect(response).to include_pagination_headers
            end
          end
        end

        context 'with public builds' do
          let(:forked_project) do
            fork_project(project, fork_user, repository: true).tap do |new_project|
              new_project.project_feature.update!(builds_access_level: ProjectFeature::ENABLED)
            end
          end

          context 'for the target project member' do
            it 'does not respond with serialized pipelines' do
              expect(json_response['pipelines']).to be_present
              expect(json_response['count']['all']).to eq(1)
              expect(response).to include_pagination_headers
            end
          end

          context 'for the source project member' do
            let(:user) { fork_user }

            it 'responds with serialized pipelines' do
              expect(json_response['pipelines']).to be_present
              expect(json_response['count']['all']).to eq(1)
              expect(response).to include_pagination_headers
            end
          end
        end
      end
    end

    context 'with pagination' do
      before do
        create(:ci_pipeline, project: merge_request.source_project, ref: merge_request.source_branch, sha: merge_request.diff_head_sha)
      end

      it 'paginates the result' do
        allow(Ci::Pipeline).to receive(:default_per_page).and_return(1)

        get :pipelines, params: { namespace_id: project.namespace.to_param, project_id: project, id: merge_request.iid }, format: :json

        expect(json_response['pipelines'].count).to eq(1)
      end
    end
  end

  describe 'GET context commits' do
    it 'returns the commits for context commits' do
      get :context_commits,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: 'json'

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response).to be_an Array
    end
  end

  describe 'GET exposed_artifacts' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project)
    end

    let(:pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha)
    end

    let!(:job) { create(:ci_build, pipeline: pipeline, options: job_options) }
    let!(:job_metadata) { create(:ci_job_artifact, :metadata, job: job) }

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:find_exposed_artifacts)
        .and_return(report)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(pipeline)
    end

    subject do
      get :exposed_artifacts,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: :json
    end

    describe 'permissions on a public project with private CI/CD' do
      let(:project) { create :project, :repository, :public, :builds_private }
      let(:report) { { status: :parsed, data: [] } }
      let(:job_options) { {} }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
    end

    context 'when pipeline has jobs with exposed artifacts' do
      let(:job_options) do
        {
          artifacts: {
            paths: ['ci_artifacts.txt'],
            expose_as: 'Exposed artifact'
          }
        }
      end

      context 'when fetching exposed artifacts is in progress' do
        let(:report) { { status: :parsing } }

        it 'sends polling interval' do
          expect(Gitlab::PollingInterval).to receive(:set_header)

          subject
        end

        it 'returns 204 HTTP status' do
          subject

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when fetching exposed artifacts is completed' do
        let(:data) do
          Ci::GenerateExposedArtifactsReportService.new(project, user)
            .execute(nil, pipeline)
        end

        let(:report) { { status: :parsed, data: data } }

        it 'returns exposed artifacts' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['status']).to eq('parsed')
          expect(json_response['data']).to eq([{
            'job_name' => 'test',
            'job_path' => project_job_path(project, job),
            'url' => file_project_job_artifacts_path(project, job, 'ci_artifacts.txt'),
            'text' => 'Exposed artifact'
          }])
        end
      end
    end

    context 'when pipeline does not have jobs with exposed artifacts' do
      let(:report) { double }
      let(:job_options) do
        {
          artifacts: {
            paths: ['ci_artifacts.txt']
          }
        }
      end

      it 'returns no content' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'GET coverage_reports' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project)
    end

    let(:pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha)
    end

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:find_coverage_reports)
        .and_return(report)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(pipeline)
    end

    subject do
      get :coverage_reports,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: :json
    end

    describe 'permissions on a public project with private CI/CD' do
      let(:project) { create :project, :repository, :public, :builds_private }
      let(:report) { { status: :parsed, data: [] } }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
    end

    context 'when pipeline has jobs with coverage reports' do
      before do
        allow_any_instance_of(MergeRequest)
          .to receive(:has_coverage_reports?)
          .and_return(true)
      end

      context 'when processing coverage reports is in progress' do
        let(:report) { { status: :parsing } }

        it 'sends polling interval' do
          expect(Gitlab::PollingInterval).to receive(:set_header)

          subject
        end

        it 'returns 204 HTTP status' do
          subject

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when processing coverage reports is completed' do
        let(:report) { { status: :parsed, data: { 'files' => {} } } }

        it 'returns coverage reports' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'files' => {} })
        end
      end

      context 'when user created corrupted coverage reports' do
        let(:report) { { status: :error, status_reason: error_string } }
        let(:error_string) { 'Failed to parse coverage reports' }

        it_behaves_like 'a 400 response'
      end
    end

    context 'when pipeline does not have jobs with coverage reports' do
      let(:report) { double }

      it 'returns no content' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'GET codequality_mr_diff_reports' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project)
    end

    let(:pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha)
    end

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:find_codequality_mr_diff_reports)
        .and_return(report)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(pipeline)
    end

    subject(:get_codequality_mr_diff_reports) do
      get :codequality_mr_diff_reports,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: :json
    end

    context 'permissions on a public project with private CI/CD' do
      let(:project) { create :project, :repository, :public, :builds_private }
      let(:report) { { status: :parsed, data: { 'files' => {} } } }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          get_codequality_mr_diff_reports

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          get_codequality_mr_diff_reports

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
    end

    context 'when pipeline has jobs with codequality mr diff report' do
      before do
        allow_any_instance_of(MergeRequest)
          .to receive(:has_codequality_mr_diff_report?)
          .and_return(true)
      end

      context 'when processing codequality mr diff report is in progress' do
        let(:report) { { status: :parsing } }

        it 'sends polling interval' do
          expect(Gitlab::PollingInterval).to receive(:set_header)

          get_codequality_mr_diff_reports
        end

        it 'returns 204 HTTP status' do
          get_codequality_mr_diff_reports

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when processing codequality mr diff report is completed' do
        let(:report) { { status: :parsed, data: { 'files' => {} } } }

        it 'returns codequality mr diff report' do
          get_codequality_mr_diff_reports

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'files' => {} })
        end
      end
    end
  end

  describe 'GET terraform_reports' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project)
    end

    let(:pipeline) do
      create(:ci_pipeline,
        :success,
        :with_terraform_reports,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha)
    end

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:find_terraform_reports)
        .and_return(report)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(pipeline)
    end

    subject do
      get :terraform_reports,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: :json
    end

    describe 'permissions on a public project with private CI/CD' do
      let(:project) { create :project, :repository, :public, :builds_private }
      let(:report) { { status: :parsed, data: [] } }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
    end

    context 'when pipeline has jobs with terraform reports' do
      before do
        allow_next_instance_of(MergeRequest) do |merge_request|
          allow(merge_request).to receive(:has_terraform_reports?).and_return(true)
        end
      end

      context 'when processing terraform reports is in progress' do
        let(:report) { { status: :parsing } }

        it 'sends polling interval' do
          expect(Gitlab::PollingInterval).to receive(:set_header)

          subject
        end

        it 'returns 204 HTTP status' do
          subject

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when processing terraform reports is completed' do
        let(:report) { { status: :parsed, data: pipeline.terraform_reports.plans } }

        it 'returns terraform reports' do
          subject

          expect(response).to have_gitlab_http_status(:ok)

          pipeline.builds.each do |build|
            expect(json_response).to match(
              a_hash_including(
                build.id.to_s => hash_including(
                  'create' => 0,
                  'delete' => 0,
                  'update' => 1,
                  'job_name' => build.name
                )
              )
            )
          end
        end
      end

      context 'when user created corrupted terraform reports' do
        let(:report) { { status: :error, status_reason: error_string } }
        let(:error_string) { 'Failed to parse terraform reports' }

        it_behaves_like 'a 400 response'
      end
    end

    context 'when pipeline does not have jobs with terraform reports' do
      before do
        allow_next_instance_of(MergeRequest) do |merge_request|
          allow(merge_request).to receive(:has_terraform_reports?).and_return(false)
        end
      end

      let(:report) { { status: :error } }

      it 'returns error' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'GET test_reports' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project
      )
    end

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
        .to receive(:compare_test_reports)
        .and_return(comparison_status)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(merge_request.all_pipelines.take)
    end

    describe 'permissions on a public project with private CI/CD' do
      let(:project) { create :project, :repository, :public, :builds_private }
      let(:comparison_status) { { status: :parsed, data: { summary: 1 } } }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
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
      let(:error_string) { 'Failed to parse test reports' }
      let(:comparison_status) { { status: :error, status_reason: error_string } }

      it_behaves_like 'a 400 response'
    end
  end

  describe 'GET accessibility_reports' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project
      )
    end

    let(:pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha)
    end

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:compare_accessibility_reports)
        .and_return(accessibility_comparison)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(pipeline)
    end

    subject do
      get :accessibility_reports,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: :json
    end

    context 'permissions on a public project with private CI/CD' do
      let(:project) { project_public_with_private_builds }
      let(:accessibility_comparison) { { status: :parsed, data: { summary: 1 } } }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
    end

    context 'when pipeline has jobs with accessibility reports' do
      before do
        allow_any_instance_of(MergeRequest)
          .to receive(:has_accessibility_reports?)
          .and_return(true)
      end

      context 'when processing accessibility reports is in progress' do
        let(:accessibility_comparison) { { status: :parsing } }

        it 'sends polling interval' do
          expect(Gitlab::PollingInterval).to receive(:set_header)

          subject
        end

        it 'returns 204 HTTP status' do
          subject

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when processing accessibility reports is completed' do
        let(:accessibility_comparison) { { status: :parsed, data: { summary: 1 } } }

        it 'returns accessibility reports' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'summary' => 1 })
        end
      end

      context 'when user created corrupted accessibility reports' do
        let(:error_string) { 'This merge request does not have accessibility reports' }
        let(:accessibility_comparison) { { status: :error, status_reason: error_string } }

        it_behaves_like 'a 400 response'
      end
    end
  end

  describe 'GET codequality_reports' do
    let_it_be(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        target_project: project,
        source_project: project
      )
    end

    let(:pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha)
    end

    before do
      allow_any_instance_of(MergeRequest)
        .to receive(:compare_codequality_reports)
        .and_return(codequality_comparison)

      allow_any_instance_of(MergeRequest)
        .to receive(:diff_head_pipeline)
        .and_return(pipeline)
    end

    subject do
      get :codequality_reports,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        },
        format: :json
    end

    context 'permissions on a public project with private CI/CD' do
      let(:project) { project_public_with_private_builds }
      let(:codequality_comparison) { { status: :parsed, data: { summary: 1 } } }

      context 'while signed out' do
        before do
          sign_out(user)
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end

      context 'while signed in as an unrelated user' do
        before do
          sign_in(create(:user))
        end

        it 'responds with a 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to be_blank
        end
      end
    end

    context 'when pipeline has jobs with codequality reports' do
      before do
        allow_any_instance_of(MergeRequest)
          .to receive(:has_codequality_reports?)
          .and_return(true)
      end

      context 'when processing codequality reports is in progress' do
        let(:codequality_comparison) { { status: :parsing } }

        it 'sends polling interval' do
          expect(Gitlab::PollingInterval).to receive(:set_header)

          subject
        end

        it 'returns 204 HTTP status' do
          subject

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when processing codequality reports is completed' do
        let(:codequality_comparison) { { status: :parsed, data: { summary: 1 } } }

        it 'returns codequality reports' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'summary' => 1 })
        end
      end
    end

    context 'when pipeline has job without a codequality report' do
      let(:error_string) { 'no codequality report' }
      let(:codequality_comparison) { { status: :error, status_reason: error_string } }

      it_behaves_like 'a 400 response'
    end
  end

  describe 'POST remove_wip' do
    before do
      merge_request.title = merge_request.draft_title
      merge_request.save!

      post :remove_wip,
        params: {
          format: :json,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid
        },
        xhr: true
    end

    it 'removes the draft status' do
      expect(merge_request.reload.title).to eq(merge_request.draftless_title)
    end

    it 'renders MergeRequest as JSON' do
      expect(json_response.keys).to include('id', 'iid', 'title', 'has_ci', 'current_user')
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

      expect(json_response.keys).to include('id', 'iid', 'title', 'has_ci', 'current_user')
    end
  end

  describe 'POST assign_related_issues' do
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project) }

    def post_assign_issues
      merge_request.update!(
        description: "Closes #{issue1.to_reference} and #{issue2.to_reference}",
        author: user,
        source_branch: 'feature',
        target_branch: 'master'
      )

      post :assign_related_issues, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    it 'displays an flash error message on fail' do
      allow(MergeRequests::AssignIssuesService).to receive(:new).and_return(double(execute: { count: 0 }))

      post_assign_issues

      expect(flash[:alert]).to eq _('Failed to assign you issues related to the merge request.')
    end

    it 'shows a flash message on success' do
      issue2.assignees = [user]

      post_assign_issues

      expect(flash[:notice]).to eq n_("An issue has been assigned to you.", "%d issues have been assigned to you.", 1)
    end

    it 'correctly pluralizes flash message on success' do
      post_assign_issues

      expect(flash[:notice]).to eq n_("An issue has been assigned to you.", "%d issues have been assigned to you.", 2)
    end

    it 'calls MergeRequests::AssignIssuesService' do
      expect(MergeRequests::AssignIssuesService).to receive(:new)
        .with(project: project, current_user: user, params: { merge_request: merge_request })
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
      let!(:build) { create(:ci_build, :with_deployment, environment: environment.name, pipeline: pipeline) }

      let(:merge_request) do
        create(:merge_request, source_project: forked, target_project: project, target_branch: 'master', head_pipeline: pipeline)
      end

      it 'links to the environment on that project' do
        get_ci_environments_status

        expect(json_response.first['url']).to match(/#{forked.full_path}/)
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
          let!(:post_merge_build)   { create(:ci_build, :with_deployment, environment: source_environment.name, pipeline: post_merge_pipeline) }

          before do
            merge_request.update!(merge_commit_sha: merge_commit_sha)
            merge_request.mark_as_merged!
          end

          it 'returns the environment on the source project' do
            get_ci_environments_status(environment_target: 'merge_commit')

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.first['url']).to match(/#{project.full_path}/)
          end
        end
      end

      # we're trying to reduce the overall number of queries for this method.
      # set a hard limit for now. https://gitlab.com/gitlab-org/gitlab-foss/issues/52287
      it 'keeps queries in check' do
        control_count = ActiveRecord::QueryRecorder.new { get_ci_environments_status }.count

        expect(control_count).to be <= 137
      end

      it 'has no N+1 SQL issues for environments', :request_store, retry: 0 do
        # First run to insert test data from lets, which does take up some 30 queries
        get_ci_environments_status

        control_count = ActiveRecord::QueryRecorder.new { get_ci_environments_status }

        environment2 = create(:environment, project: forked)
        create(:deployment, :succeed, environment: environment2, sha: sha, ref: 'master', deployable: build)

        expect { get_ci_environments_status }.not_to exceed_all_query_limit(control_count)
      end
    end

    context 'when a merge request has multiple environments with deployments' do
      let(:sha) { merge_request.diff_head_sha }
      let!(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }
      let!(:environment) { create(:environment, name: 'env_a', project: project) }
      let!(:another_environment) { create(:environment, name: 'env_b', project: project) }

      before do
        merge_request.update_head_pipeline

        create(:ci_build, :with_deployment, environment: environment.name, pipeline: pipeline)
        create(:ci_build, :with_deployment, environment: another_environment.name, pipeline: pipeline)
      end

      it 'exposes multiple environment statuses' do
        get_ci_environments_status

        expect(json_response.count).to eq 2
      end

      context 'when route map is not present in the project' do
        it 'does not have N+1 Gitaly requests for environments', :request_store do
          expect(merge_request).to be_present

          expect { get_ci_environments_status }
            .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(1)
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
            .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(1)
        end
      end
    end

    it 'uses the explicitly linked deployments' do
      expect(EnvironmentStatus)
        .to receive(:for_deployed_merge_request)
        .with(merge_request, user)
        .and_call_original

      get_ci_environments_status(environment_target: 'merge_commit')
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
        create(
          :ci_pipeline,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha,
          head_pipeline_of: merge_request
        )
      end

      let(:status) { pipeline.detailed_status(double('user')) }

      it 'returns a detailed head_pipeline status in json' do
        get_pipeline_status

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['text']).to eq status.text
        expect(json_response['label']).to eq status.label
        expect(json_response['icon']).to eq status.icon
        expect(json_response['favicon']).to match_asset_path "/assets/ci_favicons/#{status.favicon}.png"
      end

      context 'with project member visibility on a public project' do
        let(:user)    { create(:user) }
        let(:project) { project_public_with_private_builds }

        it 'returns pipeline data to project members' do
          project.add_developer(user)

          get_pipeline_status

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['text']).to eq status.text
          expect(json_response['label']).to eq status.label
          expect(json_response['icon']).to eq status.icon
          expect(json_response['favicon']).to match_asset_path "/assets/ci_favicons/#{status.favicon}.png"
        end

        it 'returns blank OK response to non-project-members' do
          get_pipeline_status

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_empty
        end
      end
    end

    context 'when head_pipeline does not exist' do
      before do
        get_pipeline_status
      end

      it 'returns blank OK response' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    def get_pipeline_status
      get :pipeline_status, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid
      }, format: :json
    end
  end

  describe 'POST #rebase' do
    let(:other_params) { {} }
    let(:params) { { namespace_id: project.namespace, project_id: project, id: merge_request }.merge(other_params) }

    def post_rebase
      post :rebase, params: params
    end

    before do
      allow(RebaseWorker).to receive(:with_status).and_return(RebaseWorker)
    end

    def expect_rebase_worker_for(user, skip_ci: false)
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, user.id, skip_ci)
    end

    context 'successfully' do
      shared_examples 'successful rebase scheduler' do
        it 'enqueues a RebaseWorker' do
          expect_rebase_worker_for(user, skip_ci: skip_ci)

          post_rebase

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with skip_ci not specified' do
        let(:skip_ci) { false }

        it_behaves_like 'successful rebase scheduler'
      end

      context 'with skip_ci enabled' do
        let(:skip_ci) { true }
        let(:other_params) { { skip_ci: 'true' } }

        it_behaves_like 'successful rebase scheduler'
      end

      context 'with skip_ci disabled' do
        let(:skip_ci) { false }
        let(:other_params) { { skip_ci: 'false' } }

        it_behaves_like 'successful rebase scheduler'
      end
    end

    context 'with NOWAIT lock' do
      it 'returns a 409' do
        allow_any_instance_of(MergeRequest).to receive(:with_lock).with('FOR UPDATE NOWAIT').and_raise(ActiveRecord::LockWaitTimeout)
        expect(RebaseWorker).not_to receive(:perform_async)

        post_rebase

        expect(response).to have_gitlab_http_status(:conflict)
        expect(json_response['merge_error']).to eq('Failed to enqueue the rebase operation, possibly due to a long-lived transaction. Try again later.')
      end
    end

    context 'when source branch is protected from force push' do
      before do
        create(:protected_branch, project: project, name: merge_request.source_branch, allow_force_push: false)
      end

      it 'returns 403' do
        expect_rebase_worker_for(user).never

        post_rebase

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['merge_error']).to eq('Source branch is protected from force push')
      end
    end

    context 'with a forked project' do
      let(:forked_project) { fork_project(project, fork_owner, repository: true) }
      let(:fork_owner) { create(:user) }
      let(:merge_request_source_project) { forked_project }

      context 'user cannot push to source branch' do
        before do
          project.add_developer(fork_owner)

          forked_project.add_reporter(user)
        end

        it 'returns 403' do
          expect_rebase_worker_for(user).never

          post_rebase

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['merge_error']).to eq('Cannot push to source branch')
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

          expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'highlight preloading' do
        context 'with commit diff notes' do
          let!(:first_commit_diff_note) do
            create(:diff_note_on_commit, project: merge_request.project)
          end

          let!(:second_commit_diff_note) do
            create(:diff_note_on_commit, project: merge_request.project)
          end

          it 'preloads all of the notes diffs highlights' do
            expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
              first_note_diff_file = first_commit_diff_note.note_diff_file
              second_note_diff_file = second_commit_diff_note.note_diff_file

              expect(collection).to receive(:load_highlight).with(diff_note_ids: [first_commit_diff_note.id, second_commit_diff_note.id]).and_call_original
              expect(collection).to receive(:find_by_id).with(first_note_diff_file.id).and_call_original
              expect(collection).to receive(:find_by_id).with(second_note_diff_file.id).and_call_original
            end

            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid,
                                        per_page: 2 }
          end

          it 'preloads all of the notes diffs highlights when per_page is 1' do
            expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
              first_note_diff_file = first_commit_diff_note.note_diff_file
              second_note_diff_file = second_commit_diff_note.note_diff_file

              expect(collection).to receive(:load_highlight).with(diff_note_ids: [first_commit_diff_note.id]).and_call_original
              expect(collection).to receive(:find_by_id).with(first_note_diff_file.id).and_call_original
              expect(collection).not_to receive(:find_by_id).with(second_note_diff_file.id)
            end

            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid,
                                        per_page: 1 }
          end
        end

        context 'with diff notes' do
          let!(:diff_note) do
            create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project)
          end

          it 'preloads notes diffs highlights' do
            expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
              note_diff_file = diff_note.note_diff_file

              expect(collection).to receive(:load_highlight).with(diff_note_ids: [diff_note.id]).and_call_original
              expect(collection).to receive(:find_by_id).with(note_diff_file.id).and_call_original
            end

            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: merge_request.iid }
          end
        end
      end

      context do
        it_behaves_like 'discussions provider' do
          let!(:author) { create(:user) }
          let_it_be_with_refind(:project) { create(:project) }

          let!(:merge_request) { create(:merge_request, source_project: project) }

          let!(:mr_note1) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
          let!(:mr_note2) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }

          let(:requested_iid) { merge_request.iid }
          let(:expected_discussion_count) { 2 }
          let(:expected_discussion_ids) { [mr_note1.discussion_id, mr_note2.discussion_id] }
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

  describe 'POST export_csv' do
    subject { post :export_csv, params: { namespace_id: project.namespace, project_id: project } }

    it 'redirects to the merge request index' do
      subject

      expect(response).to redirect_to(project_merge_requests_path(project))
      expect(controller).to set_flash[:notice].to match(/\AYour CSV export has started/i)
    end

    it 'enqueues an IssuableExportCsvWorker worker' do
      expect(IssuableExportCsvWorker).to receive(:perform_async).with(:merge_request, user.id, project.id, anything)

      subject
    end
  end

  describe '#append_info_to_payload' do
    it 'appends diffs_files_count for logging' do
      expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
        method.call(payload)

        expect(payload[:metadata]['meta.diffs_files_count']).to eq(merge_request.merge_request_diff.files_count)
      end

      get :diffs, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end
  end
end
