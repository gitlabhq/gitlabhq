# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin manages user identities', feature_category: :user_management do
  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    enable_admin_mode!(current_user, use_ui: true)
  end

  describe 'GET /admin/users/:id' do
    describe 'show user identities' do
      it 'shows user identities', :aggregate_failures do
        visit admin_user_identities_path(user)

        expect(page).to(
          have_content(user.name)
            .and(have_content('twitter'))
        )
      end
    end

    describe 'update user identities' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:twitter, :twitter_updated])
      end

      it 'modifies twitter identity', :aggregate_failures do
        visit admin_user_identities_path(user)

        find('.table').find(:link, 'Edit').click
        fill_in 'identity_extern_uid', with: '654321'
        select 'twitter_updated', from: 'identity_provider'
        click_button 'Save changes'

        expect(page).to have_content(user.name)
        expect(page).to have_content('twitter_updated')
        expect(page).to have_content('654321')
      end
    end

    describe 'remove user with identities' do
      it 'removes user with twitter identity', :aggregate_failures do
        visit admin_user_identities_path(user)

        click_link 'Delete'

        expect(page).to have_content(user.name)
        expect(page).not_to have_content('twitter')
      end
    end
  end
end
