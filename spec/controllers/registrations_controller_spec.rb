require 'spec_helper'

describe RegistrationsController do
  describe '#create' do
    around(:each) do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    let(:user_params) { { user: { name: "new_user", username: "new_username", email: "new@user.com", password: "Any_password" } } }

    context 'when sending email confirmation' do
      before { allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(false) }

      it 'logs user in directly' do
        expect { post(:create, user_params) }.not_to change{ ActionMailer::Base.deliveries.size }
        expect(subject.current_user).not_to be_nil
      end
    end

    context 'when not sending email confirmation' do
      before { allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(true) }

      it 'does not authenticate user and sends confirmation email' do
        post(:create, user_params)
        expect(ActionMailer::Base.deliveries.last.to.first).to eq(user_params[:user][:email])
        expect(subject.current_user).to be_nil
      end
    end
  end
end
