# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::UserOrganizationsFinder, '#execute', feature_category: :cell do
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:another_user) { create(:user) }

  let_it_be_with_reload(:organization_user) { create(:organization_user) }

  let_it_be(:organization) { organization_user.organization }
  let_it_be(:another_organization) { create(:organization) }

  let(:current_user) { organization_user.user }
  let(:target_user) { organization_user.user }
  let(:params) { {} }

  subject(:finder) { described_class.new(current_user, target_user, params).execute }

  context 'when the current user has access to the organization' do
    it { is_expected.to contain_exactly(organization) }
  end

  context 'when the current user is an admin' do
    let(:current_user) { admin }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to contain_exactly(organization) }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_empty }
    end
  end

  context 'when the current user does not access to the organization' do
    let(:current_user) { another_user }

    it { is_expected.to be_empty }
  end

  context 'when the current user is nil' do
    let(:current_user) { nil }

    it { is_expected.to be_empty }
  end

  context 'when the target user is nil' do
    let(:target_user) { nil }

    it { is_expected.to be_empty }
  end

  context 'when searching by name' do
    let(:params) { { search: 'Organization' } }

    it { is_expected.to contain_exactly(organization) }
  end

  context 'when searching by path' do
    let(:params) { { search: 'organization' } }

    it { is_expected.to contain_exactly(organization) }
  end

  context 'when solo_owned parameter is true' do
    let_it_be(:organization_owner) { create(:user) }

    let(:current_user) { organization_owner }
    let(:target_user) { organization_owner }
    let(:params) { { solo_owned: true } }

    it_behaves_like 'resolves user solo-owned organizations'
  end
end
