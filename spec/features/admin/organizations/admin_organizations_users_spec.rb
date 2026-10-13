# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Organizations::Users", feature_category: :user_management do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:organization_admin) { create(:user, :organization_owner) }
  let_it_be(:regular_user) { create(:user) }

  before do
    sign_in(organization_admin)
  end

  describe 'user search', :js do
    it 'allows searching by name' do
      visit organization_admin_users_path(organization, search_query: regular_user.name)

      expect(page).to have_content(regular_user.name)
    end

    it 'does not allow searching by email' do
      visit organization_admin_users_path(organization, search_query: regular_user.email)

      expect(page).not_to have_content(regular_user.name)
    end
  end
end
