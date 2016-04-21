require 'spec_helper'

describe RegistrationsController do
  describe '#create' do
    around(:each) do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    let(:user_params) { { "user"=> {"name"=>"new_user", "username"=>"new_username", "email"=>"new@user.com", "password"=>"Any_password"} } }

    context 'when skipping email confirmation' do
      before { allow(current_application_settings).to receive(:skip_user_confirmation_email).and_return(true) }

      it 'logs user in directly' do
        post(:create, user_params)
        expect(ActionMailer::Base.deliveries.last).to be_nil
        expect(subject.current_user).to be
      end
    end

    context 'when not skipping email confirmation' do
      before { allow(current_application_settings).to receive(:skip_user_confirmation_email).and_return(false) }

      it 'does not authenticate user and sends confirmation email' do
        post(:create, user_params)
        expect(ActionMailer::Base.deliveries.last.to.first).to eq(user_params["user"]["email"])
        expect(subject.current_user).to be_nil
      end
    end
  end
end
