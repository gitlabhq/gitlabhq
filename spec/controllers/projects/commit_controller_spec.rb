# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitController do
  include ProjectForksHelper

  let_it_be(:project)  { create(:project, :repository) }
  let_it_be(:user)     { create(:user) }

  let(:commit) { project.commit("master") }
  let(:master_pickable_sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }
  let(:master_pickable_commit) { project.commit(master_pickable_sha) }
  let(:pipeline) { create(:ci_pipeline, project: project, ref: project.default_branch, sha: commit.sha, status: :running) }
  let(:build) { create(:ci_build, pipeline: pipeline, status: :running) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET show' do
    render_views

    def go(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :show, params: params.merge(extra_params)
    end

    context 'with valid id' do
      it 'responds with 200' do
        go(id: commit.id)

        expect(response).to be_ok
      end

      context 'when a pipeline job is running' do
        before do
          build.run
        end

        it 'defines last pipeline information' do
          go(id: commit.id)

          expect(assigns(:last_pipeline)).to have_attributes(id: pipeline.id, status: 'running')
          expect(assigns(:last_pipeline_stages)).not_to be_empty
        end
      end
    end

    context 'with invalid id' do
      it 'responds with 404' do
        go(id: commit.id.reverse)

        expect(response).to be_not_found
      end
    end

    it 'handles binary files' do
      go(id: TestEnv::BRANCH_SHA['binary-encoding'], format: 'html')

      expect(response).to be_successful
    end

    shared_examples "export as" do |format|
      it "does generally work" do
        go(id: commit.id, format: format)

        expect(response).to be_successful
      end

      it "generates it" do
        expect_any_instance_of(Commit).to receive(:"to_#{format}")

        go(id: commit.id, format: format)
      end

      it "renders it" do
        go(id: commit.id, format: format)

        expect(response.body).to eq(commit.send(:"to_#{format}"))
      end

      it "does not escape Html" do
        allow_any_instance_of(Commit).to receive(:"to_#{format}")
          .and_return('HTML entities &<>" ')

        go(id: commit.id, format: format)

        expect(response.body).not_to include('&amp;')
        expect(response.body).not_to include('&gt;')
        expect(response.body).not_to include('&lt;')
        expect(response.body).not_to include('&quot;')
      end
    end

    describe "as diff" do
      it "triggers workhorse to serve the request" do
        go(id: commit.id, format: :diff)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-diff:")
      end
    end

    describe "as patch" do
      it "contains a git diff" do
        go(id: commit.id, format: :patch)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-format-patch:")
      end
    end

    context 'commit that removes a submodule' do
      render_views

      let(:fork_project) { create(:forked_project_with_submodules, visibility_level: 20) }
      let(:commit) { fork_project.commit('remove-submodule') }

      it 'renders it' do
        get(:show,
            params: {
              namespace_id: fork_project.namespace,
              project_id: fork_project,
              id: commit.id
            })

        expect(response).to be_successful
      end
    end

    context 'in the context of a merge_request' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:commit) { merge_request.commits.first }

      it 'prepare diff notes in the context of the merge request' do
        go(id: commit.id, merge_request_iid: merge_request.iid)

        expect(assigns(:new_diff_note_attrs)).to eq({
                                                      noteable_type: 'MergeRequest',
                                                      noteable_id: merge_request.id,
                                                      commit_id: commit.id
                                                    })
        expect(response).to be_ok
      end
    end
  end

  describe 'GET branches' do
    it 'contains branch and tags information' do
      commit = project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e')

      get(:branches,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            id: commit.id
          })

      expect(assigns(:branches)).to include('master', 'feature_conflict')
      expect(assigns(:branches_limit_exceeded)).to be_falsey
      expect(assigns(:tags)).to include('v1.1.0')
      expect(assigns(:tags_limit_exceeded)).to be_falsey
    end

    it 'returns :limit_exceeded when number of branches/tags reach a threshhold' do
      commit = project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      allow_any_instance_of(Repository).to receive(:branch_count).and_return(1001)
      allow_any_instance_of(Repository).to receive(:tag_count).and_return(1001)

      get(:branches,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            id: commit.id
          })

      expect(assigns(:branches)).to eq([])
      expect(assigns(:branches_limit_exceeded)).to be_truthy
      expect(assigns(:tags)).to eq([])
      expect(assigns(:tags_limit_exceeded)).to be_truthy
    end
  end

  describe 'POST revert' do
    context 'when target branch is not provided' do
      it 'renders the 404 page' do
        post(:revert,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              id: commit.id
            })

        expect(response).not_to be_successful
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the revert was successful' do
      it 'redirects to the commits page' do
        post(:revert,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              start_branch: 'master',
              id: commit.id
            })

        expect(response).to redirect_to project_commits_path(project, 'master')
        expect(flash[:notice]).to eq('The commit has been successfully reverted.')
      end
    end

    context 'when the revert failed' do
      before do
        post(:revert,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              start_branch: 'master',
              id: commit.id
            })
      end

      it 'redirects to the commit page' do
        # Reverting a commit that has been already reverted.
        post(:revert,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              start_branch: 'master',
              id: commit.id
            })

        expect(response).to redirect_to project_commit_path(project, commit.id)
        expect(flash[:alert]).to match('Sorry, we cannot revert this commit automatically.')
      end
    end
  end

  describe 'POST cherry_pick' do
    context 'when target branch is not provided' do
      it 'renders the 404 page' do
        post(:cherry_pick,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              id: master_pickable_commit.id
            })

        expect(response).not_to be_successful
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the cherry-pick was successful' do
      it 'redirects to the commits page' do
        post(:cherry_pick,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              start_branch: 'master',
              id: master_pickable_commit.id
            })

        expect(response).to redirect_to project_commits_path(project, 'master')
        expect(flash[:notice]).to eq('The commit has been successfully cherry-picked into master.')
      end
    end

    context 'when the cherry_pick failed' do
      before do
        post(:cherry_pick,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              start_branch: 'master',
              id: master_pickable_commit.id
            })
      end

      it 'redirects to the commit page' do
        # Cherry-picking a commit that has been already cherry-picked.
        post(:cherry_pick,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              start_branch: 'master',
              id: master_pickable_commit.id
            })

        expect(response).to redirect_to project_commit_path(project, master_pickable_commit.id)
        expect(flash[:alert]).to match('Sorry, we cannot cherry-pick this commit automatically.')
      end
    end

    context 'when a project has a fork' do
      let(:project) { create(:project, :repository) }
      let(:forked_project) { fork_project(project, user, namespace: user.namespace, repository: true) }
      let(:target_project) { project }
      let(:create_merge_request) { nil }

      def send_request
        post(:cherry_pick,
            params: {
              namespace_id: forked_project.namespace,
              project_id: forked_project,
              target_project_id: target_project.id,
              start_branch: 'feature',
              id: forked_project.commit.id,
              create_merge_request: create_merge_request
            })
      end

      def merge_request_url(source_project, branch)
        project_new_merge_request_path(
          source_project,
          merge_request: {
            source_project_id: source_project.id,
            target_project_id: project.id,
            source_branch: branch,
            target_branch: 'feature'
          }
        )
      end

      before do
        forked_project.add_maintainer(user)
      end

      it 'successfully cherry picks a commit from fork to upstream project' do
        send_request

        expect(response).to redirect_to project_commits_path(project, 'feature')
        expect(flash[:notice]).to eq('The commit has been successfully cherry-picked into feature.')
        expect(project.commit('feature').message).to include(forked_project.commit.id)
      end

      context 'when the cherry pick is performed via merge request' do
        let(:create_merge_request) { true }

        it 'successfully cherry picks a commit from fork to a cherry pick branch' do
          branch = forked_project.commit.cherry_pick_branch_name
          send_request

          expect(response).to redirect_to merge_request_url(project, branch)
          expect(flash[:notice]).to start_with("The commit has been successfully cherry-picked into #{branch}")
          expect(project.commit(branch).message).to include(forked_project.commit.id)
        end
      end

      context 'when a user cannot push to upstream project' do
        let(:create_merge_request) { true }

        before do
          project.add_reporter(user)
        end

        it 'cherry picks a commit to the fork' do
          branch = forked_project.commit.cherry_pick_branch_name
          send_request

          expect(response).to redirect_to merge_request_url(forked_project, branch)
          expect(flash[:notice]).to start_with("The commit has been successfully cherry-picked into #{branch}")
          expect(project.commit('feature').message).not_to include(forked_project.commit.id)
          expect(forked_project.commit(branch).message).to include(forked_project.commit.id)
        end
      end

      context 'when a user do not have access to the target project' do
        let(:target_project) { create(:project, :private) }

        it 'cherry picks a commit to the fork' do
          send_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :diff_for_path, params: params.merge(extra_params)
    end

    let(:existing_path) { '.gitmodules' }
    let(:commit2) { project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

    context 'when the commit exists' do
      context 'when the user has access to the project' do
        context 'when the path exists in the diff' do
          it 'enables diff notes' do
            diff_for_path(id: commit2.id, old_path: existing_path, new_path: existing_path)

            expect(assigns(:diff_notes_disabled)).to be_falsey
            expect(assigns(:new_diff_note_attrs)).to eq(noteable_type: 'Commit',
                                                        commit_id: commit2.id)
          end

          it 'only renders the diffs for the path given' do
            expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
              expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
              meth.call(diffs)
            end

            diff_for_path(id: commit2.id, old_path: existing_path, new_path: existing_path)
          end
        end

        context 'when the path does not exist in the diff' do
          before do
            diff_for_path(id: commit.id, old_path: existing_path.succ, new_path: existing_path.succ)
          end

          it 'returns a 404' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when the user does not have access to the project' do
        before do
          project.team.truncate
          diff_for_path(id: commit.id, old_path: existing_path, new_path: existing_path)
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the commit does not exist' do
      before do
        diff_for_path(id: commit.id.reverse, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET pipelines' do
    def get_pipelines(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :pipelines, params: params.merge(extra_params)
    end

    context 'when the commit exists' do
      context 'when the commit has pipelines' do
        before do
          build.run
        end

        context 'when rendering a HTML format' do
          before do
            get_pipelines(id: commit.id)
          end

          it 'shows pipelines' do
            expect(response).to be_ok
          end

          it 'defines last pipeline information' do
            expect(assigns(:last_pipeline)).to have_attributes(id: pipeline.id, status: 'running')
            expect(assigns(:last_pipeline_stages)).not_to be_empty
          end
        end

        context 'when rendering a JSON format' do
          it 'responds with serialized pipelines', :aggregate_failures do
            get_pipelines(id: commit.id, format: :json)

            expect(response).to be_ok
            expect(json_response['pipelines']).not_to be_empty
            expect(json_response['count']['all']).to eq 1
            expect(response).to include_pagination_headers
          end

          context 'with pagination' do
            let!(:extra_pipeline) { create(:ci_pipeline, project: project, ref: project.default_branch, sha: commit.sha, status: :running) }

            it 'paginates the result when ref is blank' do
              allow(Ci::Pipeline).to receive(:default_per_page).and_return(1)

              get_pipelines(id: commit.id, format: :json)

              expect(json_response['pipelines'].count).to eq(1)
            end

            it 'paginates the result when ref is present' do
              allow(Ci::Pipeline).to receive(:default_per_page).and_return(1)

              get_pipelines(id: commit.id, ref: project.default_branch, format: :json)

              expect(json_response['pipelines'].count).to eq(1)
            end
          end
        end
      end
    end

    context 'when the commit does not exist' do
      before do
        get_pipelines(id: 'e7a412c8da9f6d0081a633a4a402dde1c4694ebd')
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
