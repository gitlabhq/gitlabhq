# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User toggles subscription", :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it "unsubscribes from issue" do
    subscription_button = find('[data-testid="subscription-toggle"]')

    # Check we're subscribed.
    expect(subscription_button).to have_css("button.is-checked")

    # Toggle subscription.
    find('[data-testid="subscription-toggle"]').click
    wait_for_requests

    # Check we're unsubscribed.
    expect(subscription_button).to have_css("button:not(.is-checked)")
  end

  context 'when project emails are disabled' do
    let(:project) { create(:project_empty_repo, :public, emails_disabled: true) }

    it 'is disabled' do
      expect(page).to have_content('Disabled by project owner')
      expect(page).to have_button('Notifications', class: 'is-disabled')
    end
  end
end
