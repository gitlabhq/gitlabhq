# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersHelper, feature_category: :user_management do
  let_it_be(:current_user) { build_stubbed(:user) }

  describe 'show_admin_new_user_organization_field?' do
    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    subject { helper.show_admin_new_user_organization_field? }

    context 'when instance has organizations' do
      let_it_be(:organization) { create(:organization) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

      it { is_expected.to be(true) }

      context 'when ui_for_organizations feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when instance does not have organizations' do
      it { is_expected.to be(false) }
    end
  end

  describe 'show_admin_edit_user_organization_field?' do
    let_it_be(:organization) { create(:organization) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    subject { helper.show_admin_edit_user_organization_field?(user) }

    context 'when user has organizations' do
      let_it_be(:user) { create(:user, organizations: [organization]) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

      it { is_expected.to be(true) }

      context 'when ui_for_organizations feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when user does not have organizations' do
      let_it_be(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

      it { is_expected.to be(false) }
    end
  end

  describe 'admin_new_user_organization_field_app_data' do
    subject { Gitlab::Json.parse(helper.admin_new_user_organization_field_app_data) }

    context 'when instance has one organization' do
      let_it_be(:organization) { create(:organization) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

      it do
        is_expected.to eq({
          'has_multiple_organizations' => false,
          'initial_organization' => {
            'id' => organization.id,
            'name' => organization.name,
            'avatar_url' => organization.avatar_url(size: 96)
          }
        })
      end
    end

    context 'when instance has multiple organizations' do
      let_it_be(:organizations) { create_list(:organization, 2) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

      it do
        is_expected.to eq({
          'has_multiple_organizations' => true,
          'initial_organization' => {
            'id' => organizations.first.id,
            'name' => organizations.first.name,
            'avatar_url' => organizations.first.avatar_url(size: 96)
          }
        })
      end
    end
  end

  describe 'admin_edit_user_organization_field_app_data' do
    let_it_be(:organization) { create(:organization) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database
    let_it_be(:user) { create(:user, organizations: [organization]) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database
    let_it_be(:organization_user) { user.organization_users.first }

    subject { Gitlab::Json.parse(helper.admin_edit_user_organization_field_app_data(user)) }

    it do
      is_expected.to eq({
        'organization_user' => {
          'access_level' => organization_user.access_level,
          'id' => organization_user.id
        },
        'initial_organization' => {
          'id' => organization.id,
          'name' => organization.name,
          'avatar_url' => organization.avatar_url(size: 96)
        }
      })
    end
  end
end
