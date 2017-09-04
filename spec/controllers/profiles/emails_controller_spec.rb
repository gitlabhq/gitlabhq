require 'spec_helper'

describe Profiles::EmailsController do

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#create' do
    let(:email_params) { {email: "add_email@example.com" } }

    it 'sends an email confirmation' do
      expect {post(:create, { email: email_params })}.to change { ActionMailer::Base.deliveries.size }
      expect(ActionMailer::Base.deliveries.last.to).to eq [email_params[:email]]
      expect(ActionMailer::Base.deliveries.last.subject).to match "Confirmation instructions"
    end
  end
end
