# frozen_string_literal: true

require "spec_helper"

describe "User merges a merge request", :js do
  let(:user) { project.owner }

  before do
    sign_in(user)
  end

  shared_examples "fast forward merge a merge request" do
    it "merges a merge request" do
      expect(page).to have_content("Fast-forward merge without a merge commit").and have_button("Merge")

      page.within(".mr-state-widget") do
        click_button("Merge")
      end

      page.within(".status-box") do
        expect(page).to have_content("Merged")
      end
    end
  end

  context "ff-only merge" do
    let(:project) { create(:project, :public, :repository, merge_requests_ff_only_enabled: true) }

    before do
      visit(merge_request_path(merge_request))
    end

    context "when branch is rebased" do
      let!(:merge_request) { create(:merge_request, :rebased, source_project: project) }

      it_behaves_like "fast forward merge a merge request"
    end

    context "when branch is merged" do
      let!(:merge_request) { create(:merge_request, :merged_target, source_project: project) }

      it_behaves_like "fast forward merge a merge request"
    end
  end
end
