require 'spec_helper'

describe RegistrationsController do
  describe '#create' do
    let(:user_params) { { user: { name: 'new_user', username: 'new_username', email: 'new@user.com', password: 'Any_password', email_opted_in: email_opted_in } } }

    context 'when the user opted-in' do
      let(:email_opted_in) { '1' }

      it 'sets email_opted_in_ip to an IP' do
        post :create, user_params
        user = User.find_by_username('new_username')
        expect(user.email_opted_in_ip).to be_present
      end
    end

    context 'when the user opted-out' do
      let(:email_opted_in) { '0' }

      it 'sets email_opted_in_ip to nil' do
        post :create, user_params
        user = User.find_by_username('new_username')
        expect(user.email_opted_in_ip).to be_nil
      end
    end
  end
end
