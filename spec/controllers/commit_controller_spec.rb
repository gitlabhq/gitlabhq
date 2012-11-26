require 'spec_helper'

describe CommitController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:commit)  { project.last_commit_for("master") }

  before do
    sign_in(user)

    project.add_access(user, :read, :admin)
  end

  describe "#show" do
    shared_examples "export as" do |format|
      it "should generally work" do
        get :show, project_id: project.code, id: commit.id, format: format

        expect(response).to be_success
      end

      it "should generate it" do
        Commit.any_instance.should_receive(:"to_#{format}")

        get :show, project_id: project.code, id: commit.id, format: format
      end

      it "should render it" do
        get :show, project_id: project.code, id: commit.id, format: format

        expect(response.body).to eq(commit.send(:"to_#{format}"))
      end

      it "should not escape Html" do
        Commit.any_instance.stub(:"to_#{format}").and_return('HTML entities &<>" ')

        get :show, project_id: project.code, id: commit.id, format: format

        expect(response.body).to_not include('&amp;')
        expect(response.body).to_not include('&gt;')
        expect(response.body).to_not include('&lt;')
        expect(response.body).to_not include('&quot;')
      end
    end

    describe "as diff" do
      include_examples "export as", :diff
      let(:format) { :diff }

      it "should really only be a git diff" do
        get :show, project_id: project.code, id: commit.id, format: format

        expect(response.body).to start_with("diff --git")
      end
    end

    describe "as patch" do
      include_examples "export as", :patch
      let(:format) { :patch }

      it "should really be a git email patch" do
        get :show, project_id: project.code, id: commit.id, format: format

        expect(response.body).to start_with("From #{commit.id}")
      end

      it "should contain a git diff" do
        get :show, project_id: project.code, id: commit.id, format: format

        expect(response.body).to match(/^diff --git/)
      end
    end
  end
end
