# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User deletes branch", :js do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it "deletes branch", :js do
    visit(project_branches_path(project))

    branch_search = find('input[data-testid="branch-search"]')

    branch_search.set('improve/awesome')
    branch_search.native.send_keys(:enter)

    page.within(".js-branch-improve\\/awesome") do
      find('.js-delete-branch-button').click
    end

    page.within '.modal-footer' do
      click_button 'Yes, delete branch'
    end

    wait_for_requests

    expect(page).to have_content('Branch was deleted')
  end

  context 'when the feature flag :delete_branch_confirmation_modals is disabled' do
    before do
      stub_feature_flags(delete_branch_confirmation_modals: false)
    end

    it "deletes branch" do
      visit(project_branches_path(project))

      branch_search = find('input[data-testid="branch-search"]')

      branch_search.set('improve/awesome')
      branch_search.native.send_keys(:enter)

      page.within(".js-branch-improve\\/awesome") do
        accept_alert { click_link(title: 'Delete branch') }
      end

      wait_for_requests

      expect(page).to have_css(".js-branch-improve\\/awesome", visible: :hidden)
    end
  end
end
