require "spec_helper"

describe "Admin unsubscribes from notification" do
  set(:user) { create(:user) }
  set(:urlsafe_email) { Base64.urlsafe_encode64(user.email) }

  before do
    sign_in(user)

    visit(unsubscribe_path(urlsafe_email))
  end

  it "unsubscribes from notifications" do
    NOTIFICATION_TEXT = "You have been unsubscribed from receiving GitLab administrator notifications.".freeze

    perform_enqueued_jobs do
      click_button("Unsubscribe")
    end

    last_email = ActionMailer::Base.deliveries.last

    expect(current_path).to eq(root_path)
    expect(last_email.text_part.body.decoded).to include(NOTIFICATION_TEXT)
  end
end
