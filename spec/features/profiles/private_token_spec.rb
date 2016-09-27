require 'rails_helper'

describe 'Profile > Private tokens', feature: true do
  let(:user) { create(:user) }

  shared_examples 'private token viewer' do
    context 'when entering an invalid password' do
      before do
        login_as(user)
        visit profile_account_path
        fill_in 'current_password', with: user.password.succ
        click_on 'Show private token'
      end

      it 'shows an error and the form' do
        expect(find('#private-token-error')[:class]).not_to include('hidden')
        expect(find('#private-token-request')[:class]).not_to include('hidden')

        expect(find('#private-token-show', visible: false)[:class]).to include('hidden')
      end

      context 'when entering a valid password' do
        before do
          fill_in 'current_password', with: user.password
          click_on 'Show private token'
        end

        it 'shows only the private token' do
          expect(find('#private-token-show')[:class]).not_to include('hidden')
          expect(find('#token').value).to eq(user.private_token)

          expect(find('#private-token-error', visible: false)[:class]).to include('hidden')
          expect(find('#private-token-request', visible: false)[:class]).to include('hidden')
        end
      end
    end
  end

  context 'with JavaScript enabled', js: true do
    it_behaves_like 'private token viewer'
  end

  context 'with JavaScript disabled' do
    it_behaves_like 'private token viewer'
  end
end
