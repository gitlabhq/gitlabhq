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
end
