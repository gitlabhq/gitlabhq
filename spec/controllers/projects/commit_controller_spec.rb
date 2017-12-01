require 'spec_helper'

describe Projects::CommitController do
  set(:project)  { create(:project, :repository) }
  set(:user)     { create(:user) }
  let(:commit)   { project.commit("master") }
  let(:master_pickable_sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }
  let(:master_pickable_commit)  { project.commit(master_pickable_sha) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe 'GET show' do
    render_views

    def go(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :show, params.merge(extra_params)
    end

    context 'with valid id' do
      it 'responds with 200' do
        go(id: commit.id)

        expect(response).to be_ok
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

      expect(response).to be_success
    end

    shared_examples "export as" do |format|
      it "does generally work" do
        go(id: commit.id, format: format)

        expect(response).to be_success
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
      include_examples "export as", :diff
      let(:format) { :diff }

      it "should really only be a git diff" do
        go(id: '66eceea0db202bb39c4e445e8ca28689645366c5', format: format)

        expect(response.body).to start_with("diff --git")
      end

      it "is only be a git diff without whitespace changes" do
        go(id: '66eceea0db202bb39c4e445e8ca28689645366c5', format: format, w: 1)

        expect(response.body).to start_with("diff --git")

        # without whitespace option, there are more than 2 diff_splits for other formats
        diff_splits = assigns(:diffs).diff_files.first.diff.diff.split("\n")
        expect(diff_splits.length).to be <= 2
      end
    end

    describe "as patch" do
      include_examples "export as", :patch
      let(:format) { :patch }
      let(:commit2) { project.commit('498214de67004b1da3d820901307bed2a68a8ef6') }

      it "is a git email patch" do
        go(id: commit2.id, format: format)

        expect(response.body).to start_with("From #{commit2.id}")
      end

      it "contains a git diff" do
        go(id: commit2.id, format: format)

        expect(response.body).to match(/^diff --git/)
      end
    end

    context 'commit that removes a submodule' do
      render_views

      let(:fork_project) { create(:forked_project_with_submodules, visibility_level: 20) }
      let(:commit) { fork_project.commit('remove-submodule') }

      it 'renders it' do
        get(:show,
            namespace_id: fork_project.namespace,
            project_id: fork_project,
            id: commit.id)

        expect(response).to be_success
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
          namespace_id: project.namespace,
          project_id: project,
          id: commit.id)

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
          namespace_id: project.namespace,
          project_id: project,
          id: commit.id)

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
            namespace_id: project.namespace,
            project_id: project,
            id: commit.id)

        expect(response).not_to be_success
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the revert was successful' do
      it 'redirects to the commits page' do
        post(:revert,
            namespace_id: project.namespace,
            project_id: project,
            start_branch: 'master',
            id: commit.id)

        expect(response).to redirect_to project_commits_path(project, 'master')
        expect(flash[:notice]).to eq('The commit has been successfully reverted.')
      end
    end

    context 'when the revert failed' do
      before do
        post(:revert,
            namespace_id: project.namespace,
            project_id: project,
            start_branch: 'master',
            id: commit.id)
      end

      it 'redirects to the commit page' do
        # Reverting a commit that has been already reverted.
        post(:revert,
            namespace_id: project.namespace,
            project_id: project,
            start_branch: 'master',
            id: commit.id)

        expect(response).to redirect_to project_commit_path(project, commit.id)
        expect(flash[:alert]).to match('Sorry, we cannot revert this commit automatically.')
      end
    end
  end

  describe 'POST cherry_pick' do
    context 'when target branch is not provided' do
      it 'renders the 404 page' do
        post(:cherry_pick,
            namespace_id: project.namespace,
            project_id: project,
            id: master_pickable_commit.id)

        expect(response).not_to be_success
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the cherry-pick was successful' do
      it 'redirects to the commits page' do
        post(:cherry_pick,
            namespace_id: project.namespace,
            project_id: project,
            start_branch: 'master',
            id: master_pickable_commit.id)

        expect(response).to redirect_to project_commits_path(project, 'master')
        expect(flash[:notice]).to eq('The commit has been successfully cherry-picked.')
      end
    end

    context 'when the cherry_pick failed' do
      before do
        post(:cherry_pick,
            namespace_id: project.namespace,
            project_id: project,
            start_branch: 'master',
            id: master_pickable_commit.id)
      end

      it 'redirects to the commit page' do
        # Cherry-picking a commit that has been already cherry-picked.
        post(:cherry_pick,
            namespace_id: project.namespace,
            project_id: project,
            start_branch: 'master',
            id: master_pickable_commit.id)

        expect(response).to redirect_to project_commit_path(project, master_pickable_commit.id)
        expect(flash[:alert]).to match('Sorry, we cannot cherry-pick this commit automatically.')
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :diff_for_path, params.merge(extra_params)
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
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when the user does not have access to the project' do
        before do
          project.team.truncate
          diff_for_path(id: commit.id, old_path: existing_path, new_path: existing_path)
        end

        it 'returns a 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when the commit does not exist' do
      before do
        diff_for_path(id: commit.id.reverse, old_path: existing_path, new_path: existing_path)
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET pipelines' do
    def get_pipelines(extra_params = {})
      params = {
        namespace_id: project.namespace,
        project_id: project
      }

      get :pipelines, params.merge(extra_params)
    end

    context 'when the commit exists' do
      context 'when the commit has pipelines' do
        before do
          create(:ci_pipeline, project: project, sha: commit.id)
        end

        context 'when rendering a HTML format' do
          it 'shows pipelines' do
            get_pipelines(id: commit.id)

            expect(response).to be_ok
          end
        end

        context 'when rendering a JSON format' do
          it 'responds with serialized pipelines' do
            get_pipelines(id: commit.id, format: :json)

            expect(response).to be_ok
            expect(JSON.parse(response.body)['pipelines']).not_to be_empty
            expect(JSON.parse(response.body)['count']['all']).to eq 1
          end
        end
      end
    end

    context 'when the commit does not exist' do
      before do
        get_pipelines(id: 'e7a412c8da9f6d0081a633a4a402dde1c4694ebd')
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
