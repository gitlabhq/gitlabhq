require 'spec_helper'

describe Projects::CommitController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:commit)  { project.commit("master") }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe "#show" do
    shared_examples "export as" do |format|
      it "should generally work" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id,
            format: format)

        expect(response).to be_success
      end

      it "should generate it" do
        expect_any_instance_of(Commit).to receive(:"to_#{format}")

        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id, format: format)
      end

      it "should render it" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id, format: format)

        expect(response.body).to eq(commit.send(:"to_#{format}"))
      end

      it "should not escape Html" do
        allow_any_instance_of(Commit).to receive(:"to_#{format}").
          and_return('HTML entities &<>" ')

        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id, format: format)

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
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id,
            format: format)

        expect(response.body).to start_with("diff --git")
      end
      
      it "should really only be a git diff without whitespace changes" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: '66eceea0db202bb39c4e445e8ca28689645366c5',
            # id: commit.id,
            format: format,
            w: 1)

        expect(response.body).to start_with("diff --git")
        # without whitespace option, there are more than 2 diff_splits
        diff_splits = assigns(:diffs).first.diff.split("\n")
        expect(diff_splits.length).to be <= 2
      end
    end

    describe "as patch" do
      include_examples "export as", :patch
      let(:format) { :patch }

      it "should really be a git email patch" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id,
            format: format)

        expect(response.body).to start_with("From #{commit.id}")
      end

      it "should contain a git diff" do
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id,
            format: format)

        expect(response.body).to match(/^diff --git/)
      end
    end

    context 'commit that removes a submodule' do
      render_views

      let(:fork_project) { create(:forked_project_with_submodules) }
      let(:commit) { fork_project.commit('remove-submodule') }

      before do
        fork_project.team << [user, :master]
      end

      it 'renders it' do
        get(:show,
            namespace_id: fork_project.namespace.to_param,
            project_id: fork_project.to_param,
            id: commit.id)

        expect(response).to be_success
      end
    end
  end

  describe "#branches" do
    it "contains branch and tags information" do
      get(:branches,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: commit.id)

      expect(assigns(:branches)).to include("master", "feature_conflict")
      expect(assigns(:tags)).to include("v1.1.0")
    end
  end

  describe '#revert' do
    context 'when target branch is not provided' do
      it 'should render the 404 page' do
        post(:revert,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: commit.id)

        expect(response).not_to be_success
        expect(response.status).to eq(404)
      end
    end

    context 'when the revert was successful' do
      it 'should redirect to the commits page' do
        post(:revert,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            target_branch: 'master',
            id: commit.id)

        expect(response).to redirect_to namespace_project_commits_path(project.namespace, project, 'master')
        expect(flash[:notice]).to eq('The commit has been successfully reverted.')
      end
    end

    context 'when the revert failed' do
      before do
        post(:revert,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            target_branch: 'master',
            id: commit.id)
      end

      it 'should redirect to the commit page' do
        # Reverting a commit that has been already reverted.
        post(:revert,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            target_branch: 'master',
            id: commit.id)

        expect(response).to redirect_to namespace_project_commit_path(project.namespace, project, commit.id)
        expect(flash[:alert]).to match('Sorry, we cannot revert this commit automatically.')
      end
    end
  end
end
