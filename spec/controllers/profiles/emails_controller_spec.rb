# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::EmailsController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  describe '#create' do
    let(:email) { 'add_email@example.com' }
    let(:params) { { email: { email: email } } }

    subject { post(:create, params: params) }

    it 'sends an email confirmation' do
      expect { subject }.to change { ActionMailer::Base.deliveries.size }
    end

    context 'when email address is invalid' do
      let(:email) { 'invalid.@example.com' }

      it 'does not send an email confirmation' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.size }
      end
    end
  end

  describe '#resend_confirmation_instructions' do
    let_it_be(:email) { create(:email, user: user) }
    let(:params) { { id: email.id } }

    subject { put(:resend_confirmation_instructions, params: params) }

    it 'resends an email confirmation' do
      expect { subject }.to change { ActionMailer::Base.deliveries.size }

      expect(ActionMailer::Base.deliveries.last.to).to eq [email.email]
      expect(ActionMailer::Base.deliveries.last.subject).to match 'Confirmation instructions'
    end

    context 'email does not exist' do
      let(:params) { { id: non_existing_record_id } }

      it 'does not send an email confirmation' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.size }
      end
    end
  end
end
