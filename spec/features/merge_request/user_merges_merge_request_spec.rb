# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User merges a merge request", :js, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples "fast forward merge a merge request" do
    it "merges a merge request", :sidekiq_inline do
      expect(page).to have_content("Fast-forward merge without a merge commit").and have_button("Merge")

      page.within(".mr-state-widget") do
        click_button("Merge")
      end

      expect(page).to have_selector('.gl-badge', text: 'Merged')
    end
  end

  # Pending re-implementation: https://gitlab.com/gitlab-org/gitlab/-/issues/429268
  xcontext 'sidebar merge requests counter' do
    let_it_be(:project) { create(:project, :public, :repository, namespace: user.namespace) }
    let!(:merge_request) { create(:merge_request, source_project: project) }

    it 'decrements the open MR count', :sidekiq_inline do
      create(:merge_request, source_project: project, source_branch: 'branch-1')

      visit(merge_request_path(merge_request))

      expect(page).to have_css('.js-merge-counter', text: '2')

      page.within(".mr-state-widget") do
        click_button("Merge")
      end

      expect(page).to have_css('.js-merge-counter', text: '1')
    end
  end
end
