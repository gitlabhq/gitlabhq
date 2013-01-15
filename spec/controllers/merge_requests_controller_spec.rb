require 'spec_helper'

describe MergeRequestsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, project: project, target_branch: "bcf03b5d~3", source_branch: "bcf03b5d") }

  before do
    sign_in(user)
    project.team << [user, :master]
    MergeRequestsController.any_instance.stub(validates_merge_request: true)
  end

  describe "#show" do
    shared_examples "export as" do |format|
      it "should generally work" do
        get :show, project_id: project.code, id: merge_request.id, format: format

        expect(response).to be_success
      end

      it "should generate it" do
        MergeRequest.any_instance.should_receive(:"to_#{format}")

        get :show, project_id: project.code, id: merge_request.id, format: format
      end

      it "should render it" do
        get :show, project_id: project.code, id: merge_request.id, format: format

        expect(response.body).to eq(merge_request.send(:"to_#{format}"))
      end

      it "should not escape Html" do
        MergeRequest.any_instance.stub(:"to_#{format}").and_return('HTML entities &<>" ')

        get :show, project_id: project.code, id: merge_request.id, format: format

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
        get :show, project_id: project.code, id: merge_request.id, format: format

        expect(response.body).to start_with("diff --git")
      end
    end

    describe "as patch" do
      include_examples "export as", :patch
      let(:format) { :patch }

      it "should really be a git email patch with commit" do
        get :show, project_id: project.code, id: merge_request.id, format: format

        expect(response.body[0..100]).to start_with("From #{merge_request.commits.last.id}")
      end

      # TODO: fix or remove
      #it "should contain as many patches as there are commits" do
        #get :show, project_id: project.code, id: merge_request.id, format: format

        #patch_count = merge_request.commits.count
        #merge_request.commits.each_with_index do |commit, patch_num|
          #expect(response.body).to match(/^From #{commit.id}/)
          #expect(response.body).to match(/^Subject: \[PATCH #{patch_num}\/#{patch_count}\]/)
        #end
      #end

      it "should contain git diffs" do
        get :show, project_id: project.code, id: merge_request.id, format: format

        expect(response.body).to match(/^diff --git/)
      end
    end
  end
end
