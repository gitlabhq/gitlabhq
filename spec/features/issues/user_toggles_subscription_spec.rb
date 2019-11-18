# frozen_string_literal: true

require "spec_helper"

describe "User toggles subscription", :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it "unsubscribes from issue" do
    subscription_button = find(".js-issuable-subscribe-button")

    # Check we're subscribed.
    expect(subscription_button).to have_css("button.is-checked")

    # Toggle subscription.
    find(".js-issuable-subscribe-button button").click
    wait_for_requests

    # Check we're unsubscribed.
    expect(subscription_button).to have_css("button:not(.is-checked)")
  end

  context 'when project emails are disabled' do
    let(:project) { create(:project_empty_repo, :public, emails_disabled: true) }

    it 'is disabled' do
      expect(page).to have_content('Notifications have been disabled by the project or group owner')
      expect(page).not_to have_selector('.js-issuable-subscribe-button')
    end
  end
end
