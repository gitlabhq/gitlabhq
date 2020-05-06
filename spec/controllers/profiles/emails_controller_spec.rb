# frozen_string_literal: true

require 'spec_helper'

describe Profiles::EmailsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#create' do
    context 'when email address is valid' do
      let(:email_params) { { email: "add_email@example.com" } }

      it 'sends an email confirmation' do
        expect { post(:create, params: { email: email_params }) }.to change { ActionMailer::Base.deliveries.size }
      end
    end

    context 'when email address is invalid' do
      let(:email_params) { { email: "test.@example.com" } }

      it 'does not send an email confirmation' do
        expect { post(:create, params: { email: email_params }) }.not_to change { ActionMailer::Base.deliveries.size }
      end
    end
  end

  describe '#resend_confirmation_instructions' do
    let(:email_params) { { email: "add_email@example.com" } }

    it 'resends an email confirmation' do
      email = user.emails.create(email: 'add_email@example.com')

      expect { put(:resend_confirmation_instructions, params: { id: email }) }.to change { ActionMailer::Base.deliveries.size }
      expect(ActionMailer::Base.deliveries.last.to).to eq [email_params[:email]]
      expect(ActionMailer::Base.deliveries.last.subject).to match "Confirmation instructions"
    end

    it 'unable to resend an email confirmation' do
      expect { put(:resend_confirmation_instructions, params: { id: 1 }) }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end
end
