require 'spec_helper'

describe Projects::MergeRequestsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project, target_branch: "stable", source_branch: "master") }

  before do
    sign_in(user)
    project.team << [user, :master]
    Projects::MergeRequestsController.any_instance.stub(validates_merge_request: true, )
  end

  describe "#show" do
    shared_examples "export merge as" do |format|
      it "should generally work" do
        get :show, project_id: project.to_param, id: merge_request.iid, format: format

        expect(response).to be_success
      end

      it "should generate it" do
        MergeRequest.any_instance.should_receive(:"to_#{format}")

        get :show, project_id: project.to_param, id: merge_request.iid, format: format
      end

      it "should render it" do
        get :show, project_id: project.to_param, id: merge_request.iid, format: format

        expect(response.body).to eq((merge_request.send(:"to_#{format}",user)).to_s)
      end

      it "should not escape Html" do
        MergeRequest.any_instance.stub(:"to_#{format}").and_return('HTML entities &<>" ')

        get :show, project_id: project.to_param, id: merge_request.iid, format: format

        expect(response.body).to_not include('&amp;')
        expect(response.body).to_not include('&gt;')
        expect(response.body).to_not include('&lt;')
        expect(response.body).to_not include('&quot;')
      end
    end

    describe "as diff" do
      include_examples "export merge as", :diff
      let(:format) { :diff }

      it "should really only be a git diff" do
        get :show, project_id: project.to_param, id: merge_request.iid, format: format

        expect(response.body).to start_with("diff --git")
      end
    end

    describe "as patch" do
      include_examples "export merge as", :patch
      let(:format) { :patch }

      it "should really be a git email patch with commit" do
        get :show, project_id: project.to_param, id: merge_request.iid, format: format

        expect(response.body[0..100]).to start_with("From 6ea87c47f0f8a24ae031c3fff17bc913889ecd00")
      end

      it "should contain git diffs" do
        get :show, project_id: project.to_param, id: merge_request.iid, format: format

        expect(response.body).to match(/^diff --git/)
      end
    end
  end
end
