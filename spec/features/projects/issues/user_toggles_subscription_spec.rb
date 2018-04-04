require "spec_helper"

describe "User toggles subscription", :js do
  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { create(:user) }
  set(:issue) { create(:issue, project: project, author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it "unsibscribes from issue" do
    subscription_button = find(".js-issuable-subscribe-button")

    # Check we're subscribed.
    expect(subscription_button).to have_css("button.is-checked")

    # Toggle subscription.
    find(".js-issuable-subscribe-button button").click
    wait_for_requests

    # Check we're unsubscribed.
    expect(subscription_button).to have_css("button:not(.is-checked)")
  end
end
