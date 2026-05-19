# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group service accounts', feature_category: :user_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_application_setting(allow_top_level_group_owners_to_create_service_accounts: true)
  end

  describe 'landing page' do
    context 'when user is not a group owner' do
      it 'shows a 404 page' do
        sign_in(user)
        visit group_settings_service_accounts_path(group)
        expect(page).to have_css('h1', text: '404: Page not found')
      end
    end
  end

  describe 'CRUD', :js do
    before_all do
      group.add_owner(user)
    end

    before do
      sign_in(user)
    end

    it_behaves_like 'service account CRUD', path_helper_method: :group_settings_service_accounts_path do
      let_it_be(:resource) { group }
      let_it_be(:provisioning_attribute) { { provisioned_by_group: group } }
    end
  end
end
