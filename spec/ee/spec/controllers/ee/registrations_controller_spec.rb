require 'spec_helper'

describe RegistrationsController do
  describe '#create' do
    let(:user_params) { { user: { name: 'new_user', username: 'new_username', email: 'new@user.com', password: 'Any_password', email_opted_in: email_opted_in } } }

    context 'when the user opted-in' do
      let(:email_opted_in) { '1' }

      it 'sets the rest of the email_opted_in fields' do
        post :create, user_params
        user = User.find_by_username('new_username')
        expect(user.email_opted_in).to be_truthy
        expect(user.email_opted_in_ip).to be_present
        expect(user.email_opted_in_source).to eq('GitLab.com')
        expect(user.email_opted_in_at).not_to be_nil
      end
    end

    context 'when the user opted-out' do
      let(:email_opted_in) { '0' }

      it 'does not set the rest of the email_opted_in fields' do
        post :create, user_params
        user = User.find_by_username('new_username')
        expect(user.email_opted_in).to be_falsey
        expect(user.email_opted_in_ip).to be_blank
        expect(user.email_opted_in_source).to be_blank
        expect(user.email_opted_in_at).to be_nil
      end
    end
  end
end
