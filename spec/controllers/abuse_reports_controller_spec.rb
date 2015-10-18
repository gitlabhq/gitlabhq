require 'spec_helper'

describe AbuseReportsController do
  let(:reporter)    { create(:user) }
  let(:user)        { create(:user) }
  let(:message)     { "This user is a spammer" }

  before do
    sign_in(reporter)
  end

  describe "POST create" do
    context "with admin notification email set" do
      let(:admin_email) { "admin@example.com"}

      before(:each) do
        stub_application_setting(admin_notification_email: admin_email)
      end

      it "sends a notification email" do
        post :create,
          abuse_report: {
            user_id: user.id,
            message: message
          }

        email = ActionMailer::Base.deliveries.last

        expect(email.to).to eq([admin_email])
        expect(email.subject).to include(user.username)
        expect(email.text_part.body).to include(message)
      end

      it "saves the abuse report" do
        expect do
          post :create,
            abuse_report: {
              user_id: user.id,
              message: message
            }
        end.to change { AbuseReport.count }.by(1)
      end
    end

    context "without admin notification email set" do
      before(:each) do
        stub_application_setting(admin_notification_email: nil)
      end

      it "does not send a notification email" do
        expect do
          post :create,
            abuse_report: {
              user_id: user.id,
              message: message
            }
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "saves the abuse report" do
        expect do
          post :create,
            abuse_report: {
              user_id: user.id,
              message: message
            }
        end.to change { AbuseReport.count }.by(1)
      end
    end
  end

end
