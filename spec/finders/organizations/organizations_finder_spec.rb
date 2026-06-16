# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Organizations::OrganizationsFinder, feature_category: :organization do
  let_it_be(:private_organization) { create(:organization, :private, name: 'Private Organization') }
  let_it_be(:public_organization) { create(:organization, :public, name: 'Public Organization') }
  let_it_be(:user_organization) { create(:organization, :private, name: 'User Organization') }
  let_it_be(:soft_deleted_organization) do
    create(:organization, :public, name: 'Soft Deleted Organization', state: :soft_deleted)
  end

  let_it_be(:deletion_in_progress_organization) do
    create(:organization, :public, name: 'Deletion In Progress Organization', state: :deletion_in_progress)
  end

  let_it_be(:unconfirmed_organization) do
    create(:organization, :private, name: 'Unconfirmed Organization', state: :unconfirmed)
  end

  let_it_be(:user) { create(:user, organization: user_organization) }
  let_it_be(:admin) { create(:user, :admin, organization: user_organization) }

  let(:params) { {} }

  subject(:finder) { described_class.new(current_user, params).execute }

  describe 'without authentication' do
    let(:current_user) { nil }

    it 'returns public organizations that are not being deleted' do
      expect(finder).to contain_exactly(public_organization)
    end
  end

  describe 'with authenticated user' do
    let(:current_user) { user }

    it 'returns organizations the user is a member of and public organizations, excluding those being deleted' do
      expect(finder).to contain_exactly(user_organization, public_organization)
    end
  end

  describe 'with admin user without admin mode' do
    let(:current_user) { admin }

    it 'returns organizations the user is a member of and public organizations, excluding those being deleted' do
      expect(finder).to contain_exactly(user_organization, public_organization)
    end
  end

  describe 'with admin user', :enable_admin_mode do
    let(:current_user) { admin }

    it 'returns all organizations regardless of state by default' do
      expect(finder).to contain_exactly(
        private_organization, public_organization, user_organization, soft_deleted_organization,
        deletion_in_progress_organization, unconfirmed_organization
      )
    end
  end

  describe 'state filtering' do
    context 'when the current user is not an admin' do
      let(:current_user) { user }

      context 'when no state param is given' do
        it 'excludes organizations that are being deleted' do
          expect(finder).not_to include(soft_deleted_organization)
          expect(finder).not_to include(deletion_in_progress_organization)
        end

        it 'does not return organizations the user is not a member of' do
          expect(finder).not_to include(unconfirmed_organization)
        end
      end

      context 'when the user is a member of non-active organizations' do
        let_it_be(:member_unconfirmed_organization) do
          create(:organization, :private, name: 'Member Unconfirmed Organization', state: :unconfirmed).tap do |org|
            org.organization_users.create!(user: user, access_level: :default)
          end
        end

        let_it_be(:member_confirmed_organization) do
          create(:organization, :private, name: 'Member Confirmed Organization', state: :confirmed).tap do |org|
            org.organization_users.create!(user: user, access_level: :default)
          end
        end

        it 'returns unconfirmed and confirmed organizations the user is a member of, even as a non-owner' do
          expect(finder).to include(member_unconfirmed_organization, member_confirmed_organization)
        end

        context 'when filtering by one of those states' do
          let(:params) { { state: 'unconfirmed' } }

          it 'returns only the organizations in that state the user can see' do
            expect(finder).to include(member_unconfirmed_organization)
            expect(finder).not_to include(member_confirmed_organization)
          end
        end
      end

      context 'when filtering by a visible state' do
        let(:params) { { state: 'active' } }

        it 'returns only organizations in that state the user can see' do
          expect(finder).to contain_exactly(user_organization, public_organization)
        end
      end

      context 'when filtering by a deletion state' do
        let(:params) { { state: 'soft_deleted' } }

        it 'still excludes organizations being deleted' do
          expect(finder).not_to include(soft_deleted_organization)
          expect(finder).to be_empty
        end
      end
    end

    context 'when the current user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      context 'when no state param is given' do
        it 'returns all organizations regardless of state' do
          expect(finder).to include(soft_deleted_organization)
        end
      end

      context 'when state is a single value' do
        let(:params) { { state: 'soft_deleted' } }

        it 'returns only organizations with that state' do
          expect(finder).to contain_exactly(soft_deleted_organization)
        end
      end

      context 'when state is an array of values' do
        let(:params) { { state: %w[active soft_deleted] } }

        it 'returns organizations matching any of the given states' do
          expect(finder).to contain_exactly(
            private_organization, user_organization, public_organization, soft_deleted_organization
          )
        end
      end

      context 'when state contains only invalid values' do
        let(:params) { { state: 'nonexistent' } }

        it 'returns no organizations' do
          expect(finder).to be_empty
        end
      end

      context 'when state contains a mix of valid and invalid values' do
        let(:params) { { state: %w[active bogus] } }

        it 'discards invalid states and filters by the valid ones' do
          expect(finder).to contain_exactly(private_organization, user_organization, public_organization)
        end
      end
    end
  end

  describe 'exclude_default' do
    let(:current_user) { user }

    before do
      stub_const("Organizations::Organization::DEFAULT_ORGANIZATION_ID", public_organization.id)
    end

    context 'when exclude_default is true' do
      let(:params) { { exclude_default: true } }

      it 'excludes the default organization from results' do
        expect(finder).not_to include(public_organization)
      end

      it 'returns other organizations' do
        expect(finder).to include(user_organization)
      end
    end

    context 'when exclude_default is false' do
      let(:params) { { exclude_default: false } }

      it 'does not exclude any organizations' do
        expect(finder).to contain_exactly(user_organization, public_organization)
      end
    end

    context 'when exclude_default is not set' do
      let(:params) { {} }

      it 'does not exclude any organizations' do
        expect(finder).to contain_exactly(user_organization, public_organization)
      end
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
