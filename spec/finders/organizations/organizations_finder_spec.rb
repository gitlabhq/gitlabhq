# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Organizations::OrganizationsFinder, feature_category: :organization do
  let_it_be(:private_organization) { create(:organization, :private, name: 'Private Organization') }
  let_it_be(:public_organization) { create(:organization, :public, name: 'Public Organization') }
  let_it_be(:user_organization) { create(:organization, :private, name: 'User Organization') }
  let_it_be(:user) { create(:user, organization: user_organization) }
  let_it_be(:admin) { create(:user, :admin, organization: user_organization) }

  let(:params) { {} }

  subject(:finder) { described_class.new(current_user, params).execute }

  describe 'without authentication' do
    let(:current_user) { nil }

    it 'returns public organizations' do
      expect(finder).to contain_exactly(public_organization)
    end
  end

  describe 'with authenticated user' do
    let(:current_user) { user }

    it 'returns organizations the user is a member of and public organizations' do
      expect(finder).to contain_exactly(user_organization, public_organization)
    end
  end

  describe 'with admin user without admin mode' do
    let(:current_user) { admin }

    it 'returns organizations the user is a member of and public organizations' do
      expect(finder).to contain_exactly(user_organization, public_organization)
    end
  end

  describe 'with admin user', :enable_admin_mode do
    let(:current_user) { admin }

    it 'returns all organizations' do
      expect(finder).to contain_exactly(private_organization, public_organization, user_organization)
    end
  end

  describe 'search' do
    let(:current_user) { user }

    context 'when searching by name' do
      let(:params) { { search: user_organization.name } }

      it 'returns matching organization the user has access to' do
        expect(finder).to contain_exactly(user_organization)
      end
    end

    context 'when searching by path' do
      let(:params) { { search: user_organization.path } }

      it 'returns matching organization the user has access to' do
        expect(finder).to contain_exactly(user_organization)
      end
    end

    context 'when searching for organization user does not have access to' do
      let(:params) { { search: private_organization.name } }

      it 'returns empty result' do
        expect(finder).to be_empty
      end
    end
  end
end
