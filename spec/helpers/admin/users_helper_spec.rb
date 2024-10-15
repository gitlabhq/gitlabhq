# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersHelper, feature_category: :user_management do
  describe 'show_new_user_organization_field?' do
    subject { helper.show_new_user_organization_field? }

    context 'when instance has organizations', :with_default_organization do
      it { is_expected.to be(true) }
    end

    context 'when instance does not have organizations' do
      it { is_expected.to be(false) }
    end
  end

  describe 'new_user_organization_field_app_data', :with_default_organization do
    subject { Gitlab::Json.parse(helper.new_user_organization_field_app_data) }

    context 'when instance has one organization' do
      it do
        is_expected.to eq({
          'has_multiple_organizations' => false,
          'initial_organization' => {
            'id' => default_organization.id,
            'name' => default_organization.name,
            'avatar_url' => default_organization.avatar_url(size: 96)
          }
        })
      end
    end

    context 'when instance has multiple organizations' do
      let_it_be(:organization) { create(:organization) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- spec needs organization persisted to database

      it do
        is_expected.to eq({
          'has_multiple_organizations' => true,
          'initial_organization' => {
            'id' => default_organization.id,
            'name' => default_organization.name,
            'avatar_url' => default_organization.avatar_url(size: 96)
          }
        })
      end
    end
  end
end
