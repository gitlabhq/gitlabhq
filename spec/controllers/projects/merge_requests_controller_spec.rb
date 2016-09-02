require 'spec_helper'

describe Projects::MergeRequestsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_with_conflicts) do
    create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start', source_project: project) do |mr|
      mr.mark_as_unmergeable
    end
  end

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe 'GET new' do
    context 'merge request that removes a submodule' do
      render_views

      let(:fork_project) { create(:forked_project_with_submodules) }

      before do
        fork_project.team << [user, :master]
      end

      it 'renders it' do
        get :new,
            namespace_id: fork_project.namespace.to_param,
            project_id: fork_project.to_param,
            merge_request: {
              source_branch: 'remove-submodule',
              target_branch: 'master'
            }

        expect(response).to be_success
      end
    end
  end

  describe 'POST #create' do
    def create_merge_request(overrides = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        merge_request: {
          title: 'Test',
          source_branch: 'feature_conflict',
          target_branch: 'master',
          author: user
        }.merge(overrides)
      }

      post :create, params
    end

    context 'the approvals_before_merge param' do
      before { project.update_attributes(approvals_before_merge: 2) }
      let(:created_merge_request) { assigns(:merge_request) }

      context 'when it is less than the one in the target project' do
        before { create_merge_request(approvals_before_merge: 1) }

        it 'sets the param to nil' do
          expect(created_merge_request.approvals_before_merge).to eq(nil)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: created_merge_request.iid, project_id: project.to_param))
        end
      end

      context 'when it is equal to the one in the target project' do
        before { create_merge_request(approvals_before_merge: 2) }

        it 'sets the param to nil' do
          expect(created_merge_request.approvals_before_merge).to eq(nil)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: created_merge_request.iid, project_id: project.to_param))
        end
      end

      context 'when it is greater than the one in the target project' do
        before { create_merge_request(approvals_before_merge: 3) }

        it 'saves the param in the merge request' do
          expect(created_merge_request.approvals_before_merge).to eq(3)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: created_merge_request.iid, project_id: project.to_param))
        end
      end

      context 'when the target project is a fork of a deleted project' do
        before do
          original_project = create(:empty_project)
          project.update_attributes(forked_from_project: original_project, approvals_before_merge: 4)
          original_project.update_attributes(pending_delete: true)

          create_merge_request(approvals_before_merge: 3)
        end

        it 'uses the default from the target project' do
          expect(created_merge_request.approvals_before_merge).to eq(nil)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: created_merge_request.iid, project_id: project.to_param))
        end
      end
    end

    context 'when the merge request is invalid' do
      it 'shows the #new form' do
        expect(create_merge_request(title: nil)).to render_template(:new)
      end
    end
  end

  describe "GET show" do
    shared_examples "export merge as" do |format|
      it "does generally work" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response).to be_success
      end

      it "generates it" do
        expect_any_instance_of(MergeRequest).to receive(:"to_#{format}")

        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)
      end

      it "renders it" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response.body).to eq(merge_request.send(:"to_#{format}").to_s)
      end

      it "does not escape Html" do
        allow_any_instance_of(MergeRequest).to receive(:"to_#{format}").
          and_return('HTML entities &<>" ')

        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: format)

        expect(response.body).not_to include('&amp;')
        expect(response.body).not_to include('&gt;')
        expect(response.body).not_to include('&lt;')
        expect(response.body).not_to include('&quot;')
      end
    end

    describe "as diff" do
      it "triggers workhorse to serve the request" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: :diff)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-diff:")
      end
    end

    describe "as patch" do
      it 'triggers workhorse to serve the request' do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid,
            format: :patch)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-format-patch:")
      end
    end
  end

  describe 'GET index' do
    def get_merge_requests
      get :index,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          state: 'opened'
    end

    context 'when filtering by opened state' do
      context 'with opened merge requests' do
        it 'lists those merge requests' do
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
    def update_merge_request(params = {})
      post :update,
           namespace_id: project.namespace.to_param,
           project_id: project.to_param,
           id: merge_request.iid,
           merge_request: params
    end

    context 'there is no source project' do
      let(:project)       { create(:project) }
      let(:fork_project)  { create(:forked_project_with_submodules) }
      let(:merge_request) { create(:merge_request, source_project: fork_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

      before do
        fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
        fork_project.save
        merge_request.reload
        fork_project.destroy
      end

      it 'closes MR without errors' do
        update_merge_request(state_event: 'close')

        expect(response).to redirect_to([merge_request.target_project.namespace.becomes(Namespace), merge_request.target_project, merge_request])
        expect(merge_request.reload.closed?).to be_truthy
      end

      it 'allows editing of a closed merge request' do
        merge_request.close!

        put :update,
            namespace_id: project.namespace.path,
            project_id: project.path,
            id: merge_request.iid,
            merge_request: {
              title: 'New title'
            }

        expect(response).to redirect_to([merge_request.target_project.namespace.becomes(Namespace), merge_request.target_project, merge_request])
        expect(merge_request.reload.title).to eq 'New title'
      end

      it 'does not allow to update target branch closed merge request' do
        merge_request.close!

        put :update,
            namespace_id: project.namespace.path,
            project_id: project.path,
            id: merge_request.iid,
            merge_request: {
              target_branch: 'new_branch'
            }

        expect { merge_request.reload.target_branch }.not_to change { merge_request.target_branch }
      end
    end

    context 'the approvals_before_merge param' do
      before { project.update_attributes(approvals_before_merge: 2) }

      context 'when it is less than the one in the target project' do
        before { update_merge_request(approvals_before_merge: 1) }

        it 'sets the param to nil' do
          expect(merge_request.reload.approvals_before_merge).to eq(nil)
        end

        it 'updates the merge request' do
          expect(merge_request.reload).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: merge_request.iid, project_id: project.to_param))
        end
      end

      context 'when it is equal to the one in the target project' do
        before { update_merge_request(approvals_before_merge: 2) }

        it 'sets the param to nil' do
          expect(merge_request.reload.approvals_before_merge).to eq(nil)
        end

        it 'updates the merge request' do
          expect(merge_request.reload).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: merge_request.iid, project_id: project.to_param))
        end
      end

      context 'when it is greater than the one in the target project' do
        before { update_merge_request(approvals_before_merge: 3) }

        it 'saves the param in the merge request' do
          expect(merge_request.reload.approvals_before_merge).to eq(3)
        end

        it 'updates the merge request' do
          expect(merge_request.reload).to be_valid
          expect(response).to redirect_to(namespace_project_merge_request_path(id: merge_request.iid, project_id: project.to_param))
        end
      end
    end
  end

  describe 'POST merge' do
    let(:base_params) do
      {
        namespace_id: project.namespace.path,
        project_id: project.path,
        id: merge_request.iid,
        format: 'raw'
      }
    end

    context 'when the user does not have access' do
      before do
        project.team.truncate
        project.team << [user, :reporter]
        post :merge, base_params
      end

      it 'returns not found' do
        expect(response).to be_not_found
      end
    end

    context 'when the merge request is not mergeable' do
      before do
        merge_request.update_attributes(title: "WIP: #{merge_request.title}")

        post :merge, base_params
      end

      it 'returns :failed' do
        expect(assigns(:status)).to eq(:failed)
      end
    end

    context 'when the sha parameter does not match the source SHA' do
      before { post :merge, base_params.merge(sha: 'foo') }

      it 'returns :sha_mismatch' do
        expect(assigns(:status)).to eq(:sha_mismatch)
      end
    end

    context 'when the sha parameter matches the source SHA' do
      def merge_with_sha
        post :merge, base_params.merge(sha: merge_request.diff_head_sha)
      end

      it 'returns :success' do
        merge_with_sha

        expect(assigns(:status)).to eq(:success)
      end

      it 'starts the merge immediately' do
        expect(MergeWorker).to receive(:perform_async).with(merge_request.id, anything, anything)

        merge_with_sha
      end

      context 'when merge_when_build_succeeds is passed' do
        def merge_when_build_succeeds
          post :merge, base_params.merge(sha: merge_request.diff_head_sha, merge_when_build_succeeds: '1')
        end

        before do
          create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
        end

        it 'returns :merge_when_build_succeeds' do
          merge_when_build_succeeds

          expect(assigns(:status)).to eq(:merge_when_build_succeeds)
        end

        it 'sets the MR to merge when the build succeeds' do
          service = double(:merge_when_build_succeeds_service)

          expect(MergeRequests::MergeWhenBuildSucceedsService).to receive(:new).with(project, anything, anything).and_return(service)
          expect(service).to receive(:execute).with(merge_request)

          merge_when_build_succeeds
        end

        context 'when project.only_allow_merge_if_build_succeeds? is true' do
          before do
            project.update_column(:only_allow_merge_if_build_succeeds, true)
          end

          it 'returns :merge_when_build_succeeds' do
            merge_when_build_succeeds

            expect(assigns(:status)).to eq(:merge_when_build_succeeds)
          end
        end
      end
    end
  end

  describe "DELETE destroy" do
    it "denies access to users unless they're admin or project owner" do
      delete :destroy, namespace_id: project.namespace.path, project_id: project.path, id: merge_request.iid

      expect(response).to have_http_status(404)
    end

    context "when the user is owner" do
      let(:owner)     { create(:user) }
      let(:namespace) { create(:namespace, owner: owner) }
      let(:project)   { create(:project, namespace: namespace) }

      before { sign_in owner }

      it "deletes the merge request" do
        delete :destroy, namespace_id: project.namespace.path, project_id: project.path, id: merge_request.iid

        expect(response).to have_http_status(302)
        expect(controller).to set_flash[:notice].to(/The merge request was successfully deleted\./).now
      end
    end
  end

  describe 'GET diffs' do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: merge_request.iid
      }

      get :diffs, params.merge(extra_params)
    end

    context 'with default params' do
      context 'as html' do
        before { go(format: 'html') }

        it 'renders the diff template' do
          expect(response).to render_template('diffs')
        end
      end

      context 'as json' do
        before { go(format: 'json') }

        it 'renders the diffs template to a string' do
          expect(response).to render_template('projects/merge_requests/show/_diffs')
          expect(JSON.parse(response.body)).to have_key('html')
        end
      end

      context 'with forked projects with submodules' do
        render_views

        let(:project) { create(:project) }
        let(:fork_project) { create(:forked_project_with_submodules) }
        let(:merge_request) { create(:merge_request_with_diffs, source_project: fork_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

        before do
          fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
          fork_project.save
          merge_request.reload
          go(format: 'json')
        end

        it 'renders' do
          expect(response).to be_success
          expect(response.body).to have_content('Subproject commit')
        end
      end
    end

    context 'with ignore_whitespace_change' do
      context 'as html' do
        before { go(format: 'html', w: 1) }

        it 'renders the diff template' do
          expect(response).to render_template('diffs')
        end
      end

      context 'as json' do
        before { go(format: 'json', w: 1) }

        it 'renders the diffs template to a string' do
          expect(response).to render_template('projects/merge_requests/show/_diffs')
          expect(JSON.parse(response.body)).to have_key('html')
        end
      end
    end

    context 'with view' do
      before { go(view: 'parallel') }

      it 'saves the preferred diff view in a cookie' do
        expect(response.cookies['diff_view']).to eq('parallel')
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param
      }

      get :diff_for_path, params.merge(extra_params)
    end

    context 'when an ID param is passed' do
      let(:existing_path) { 'files/ruby/popen.rb' }

      context 'when the merge request exists' do
        context 'when the user can view the merge request' do
          context 'when the path exists in the diff' do
            it 'enables diff notes' do
              diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path)

              expect(assigns(:diff_notes_disabled)).to be_falsey
              expect(assigns(:comments_target)).to eq(noteable_type: 'MergeRequest',
                                                      noteable_id: merge_request.id)
            end

            it 'only renders the diffs for the path given' do
              expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
                expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
                meth.call(diffs)
              end

              diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path)
            end
          end

          context 'when the path does not exist in the diff' do
            before { diff_for_path(id: merge_request.iid, old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb') }

            it 'returns a 404' do
              expect(response).to have_http_status(404)
            end
          end
        end

        context 'when the user cannot view the merge request' do
          before do
            project.team.truncate
            diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path)
          end

          it 'returns a 404' do
            expect(response).to have_http_status(404)
          end
        end
      end

      context 'when the merge request does not exist' do
        before { diff_for_path(id: merge_request.iid.succ, old_path: existing_path, new_path: existing_path) }

        it 'returns a 404' do
          expect(response).to have_http_status(404)
        end
      end

      context 'when the merge request belongs to a different project' do
        let(:other_project) { create(:empty_project) }

        before do
          other_project.team << [user, :master]
          diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path, project_id: other_project.to_param)
        end

        it 'returns a 404' do
          expect(response).to have_http_status(404)
        end
      end
    end

    context 'when source and target params are passed' do
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
        let(:other_project) { create(:project) }

        before { other_project.team << [user, :master] }

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
          before { diff_for_path(old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb', merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' }) }

          it 'returns a 404' do
            expect(response).to have_http_status(404)
          end
        end
      end
    end
  end

  describe 'GET commits' do
    def go(format: 'html')
      get :commits,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: merge_request.iid,
          format: format
    end

    context 'as html' do
      it 'renders the show template' do
        go

        expect(response).to render_template('show')
      end
    end

    context 'as json' do
      it 'renders the commits template to a string' do
        go format: 'json'

        expect(response).to render_template('projects/merge_requests/show/_commits')
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end
  end

  describe 'GET conflicts' do
    let(:json_response) { JSON.parse(response.body) }

    context 'when the conflicts cannot be resolved in the UI' do
      before do
        allow_any_instance_of(Gitlab::Conflict::Parser).
          to receive(:parse).and_raise(Gitlab::Conflict::Parser::UnexpectedDelimiter)

        get :conflicts,
            namespace_id: merge_request_with_conflicts.project.namespace.to_param,
            project_id: merge_request_with_conflicts.project.to_param,
            id: merge_request_with_conflicts.iid,
            format: 'json'
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON with a message' do
        expect(json_response.keys).to contain_exactly('message', 'type')
      end
    end

    context 'with valid conflicts' do
      before do
        get :conflicts,
            namespace_id: merge_request_with_conflicts.project.namespace.to_param,
            project_id: merge_request_with_conflicts.project.to_param,
            id: merge_request_with_conflicts.iid,
            format: 'json'
      end

      it 'includes meta info about the MR' do
        expect(json_response['commit_message']).to include('Merge branch')
        expect(json_response['commit_sha']).to match(/\h{40}/)
        expect(json_response['source_branch']).to eq(merge_request_with_conflicts.source_branch)
        expect(json_response['target_branch']).to eq(merge_request_with_conflicts.target_branch)
      end

      it 'includes each file that has conflicts' do
        filenames = json_response['files'].map { |file| file['new_path'] }

        expect(filenames).to contain_exactly('files/ruby/popen.rb', 'files/ruby/regex.rb')
      end

      it 'splits files into sections with lines' do
        json_response['files'].each do |file|
          file['sections'].each do |section|
            expect(section).to include('conflict', 'lines')

            section['lines'].each do |line|
              if section['conflict']
                expect(line['type']).to be_in(['old', 'new'])
                expect(line.values_at('old_line', 'new_line')).to contain_exactly(nil, a_kind_of(Integer))
              else
                if line['type'].nil?
                  expect(line['old_line']).not_to eq(nil)
                  expect(line['new_line']).not_to eq(nil)
                else
                  expect(line['type']).to eq('match')
                  expect(line['old_line']).to eq(nil)
                  expect(line['new_line']).to eq(nil)
                end
              end
            end
          end
        end
      end

      it 'has unique section IDs across files' do
        section_ids = json_response['files'].flat_map do |file|
          file['sections'].map { |section| section['id'] }.compact
        end

        expect(section_ids.uniq).to eq(section_ids)
      end
    end
  end

  context 'POST resolve_conflicts' do
    let(:json_response) { JSON.parse(response.body) }
    let!(:original_head_sha) { merge_request_with_conflicts.diff_head_sha }

    def resolve_conflicts(sections)
      post :resolve_conflicts,
           namespace_id: merge_request_with_conflicts.project.namespace.to_param,
           project_id: merge_request_with_conflicts.project.to_param,
           id: merge_request_with_conflicts.iid,
           format: 'json',
           sections: sections,
           commit_message: 'Commit message'
    end

    context 'with valid params' do
      before do
        resolve_conflicts('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head',
                          '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
                          '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
                          '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin')
      end

      it 'creates a new commit on the branch' do
        expect(original_head_sha).not_to eq(merge_request_with_conflicts.source_branch_head.sha)
        expect(merge_request_with_conflicts.source_branch_head.message).to include('Commit message')
      end

      it 'returns an OK response' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when sections are missing' do
      before do
        resolve_conflicts('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head')
      end

      it 'returns a 400 error' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'has a message with the name of the first missing section' do
        expect(json_response['message']).to include('6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9')
      end

      it 'does not create a new commit' do
        expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)
      end
    end
  end
end
