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

      context 'when ui_for_organizations_enabled? is false', :ui_for_organizations_disabled do
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

      context 'when ui_for_organizations_enabled? is false', :ui_for_organizations_disabled do
        it { is_expected.to be(false) }
      end
    end

    context 'when user does not have organizations' do
      let_it_be(:user) { create(:user, organizations: []) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

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

  describe 'invite_organization_user_app_data' do
    let_it_be(:organization) { create(:organization) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

    subject { Gitlab::Json.parse(helper.invite_organization_user_app_data(organization, has_new_user_button: has_new_user_button)) }

    context 'when the New user button is also shown' do
      let(:has_new_user_button) { true }

      it do
        is_expected.to eq({
          'organization_gid' => organization.to_global_id.to_s,
          'organization_name' => organization.name,
          'search_url' => helper.autocomplete_users_path(format: :json),
          'button_variant' => 'default'
        })
      end
    end

    context 'when the New user button is not shown' do
      let(:has_new_user_button) { false }

      it { is_expected.to include('button_variant' => 'confirm') }
    end
  end

  describe 'can_edit_organization_user?', :with_current_organization do
    let_it_be(:user) { build_stubbed(:user) }

    subject { helper.can_edit_organization_user?(user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(current_organization).to receive(:membership_for).with(user).and_return(organization_user)
    end

    context 'when the user is a member of the current organization' do
      let(:organization_user) { build_stubbed(:organization_user) }

      before do
        allow(helper).to receive(:can?)
          .with(current_user, :update_organization_user, organization_user)
          .and_return(can_update)
      end

      context 'when the current user can update the organization user' do
        let(:can_update) { true }

        it { is_expected.to be(true) }
      end

      context 'when the current user cannot update the organization user' do
        let(:can_update) { false }

        it { is_expected.to be(false) }
      end
    end

    context 'when the user is not a member of the current organization' do
      let(:organization_user) { nil }

      it { is_expected.to be(false) }
    end
  end

  describe 'email_otp_status_text' do
    subject { helper.email_otp_status_text(current_user) }

    before do
      allow(current_user).to receive(:email_otp_required_after).and_return(email_otp_required_after)
    end

    context 'when user has email OTP disabled' do
      let(:email_otp_required_after) { nil }

      it { is_expected.to eq('No') }
    end

    context 'when user has email OTP enabled' do
      let(:now) { Time.current }
      let(:email_otp_required_after) { now }

      it { is_expected.to eq("Yes (#{now.to_fs(:medium)})") }
    end
  end
end
