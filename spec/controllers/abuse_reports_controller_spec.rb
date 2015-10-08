require 'spec_helper'

describe AbuseReportsController do
  let(:reporter)    { create(:user) }
  let(:user)        { create(:user) }
  let(:message)     { "This user is a spammer" }

  before do
    sign_in(reporter)
  end

  describe "with admin notification_email set" do
    let(:admin_email) { "admin@example.com"}
    before(:example) { allow(current_application_settings).to receive(:admin_notification_email).and_return(admin_email) }

    it "sends a notification email" do
      post(:create,
        abuse_report: {
          user_id: user.id,
          message: message
        }
      )

      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to start_with("Thank you for your report")

      email = ActionMailer::Base.deliveries.last

      expect(email).to          be_present
      expect(email.subject).to  eq("[Gitlab] Abuse report filed for `#{user.username}`")
      expect(email.to).to       eq([admin_email])
      expect(email.body).to     include(message)
    end
  end

  describe "without admin notification email set" do
    before(:example) { allow(current_application_settings).to receive(:admin_notification_email).and_return(nil) }

    it "does not send a notification email" do
      expect do
        post(:create,
          abuse_report: {
            user_id: user.id,
            message: message
          }
        )
      end.to_not change{ActionMailer::Base.deliveries}

      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to start_with("Thank you for your report")
    end
  end
end