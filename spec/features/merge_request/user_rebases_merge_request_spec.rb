# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User rebases a merge request", :js, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  shared_examples "rebases" do
    it "rebases" do
      visit(merge_request_path(merge_request))

      wait_for_requests

      click_button 'Expand merge checks'

      expect(page).to have_button("Rebase")

      click_button("Rebase")

      expect(find_by_testid('standard-rebase-button')).to have_selector(".gl-spinner")
    end
  end

  context "when merge is regular" do
    let(:project) { create(:project, :public, :repository, merge_requests_rebase_enabled: true) }

    it_behaves_like "rebases"
  end

  context "when merge is ff-only" do
    let(:project) { create(:project, :public, :repository, merge_requests_ff_only_enabled: true) }

    it_behaves_like "rebases"
  end
end
