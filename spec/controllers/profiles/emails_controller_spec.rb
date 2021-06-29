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

  shared_examples_for 'respects the rate limit' do
    context 'after the rate limit is exceeded' do
      before do
        allowed_threshold = Gitlab::ApplicationRateLimiter.rate_limits[action][:threshold]

        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(allowed_threshold + 1)
      end

      it 'does not send any email' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.size }
      end

      it 'displays an alert' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
        expect(flash[:alert]).to eq(_('This action has been performed too many times. Try again later.'))
      end
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

    it_behaves_like 'respects the rate limit' do
      let(:action) { :profile_add_new_email }
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

    it_behaves_like 'respects the rate limit' do
      let(:action) { :profile_resend_email_confirmation }
    end
  end
end
