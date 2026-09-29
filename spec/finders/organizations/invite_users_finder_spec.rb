# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::InviteUsersFinder, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:current_user) { create(:user, organization: organization) }

  let_it_be(:existing_member) do
    create(:user, organization: organization, name: 'Zed Member', username: 'zed-member')
  end

  let_it_be(:invitable_user) do
    create(:user, organization: other_organization, name: 'Zed Candidate', username: 'zed-candidate')
  end

  let_it_be(:external_user) { create(:user, :external, organization: other_organization) }
  let_it_be(:unconfirmed_user) { create(:user, confirmed_at: nil, organization: other_organization) }
  let_it_be(:service_account_user) { create(:user, :service_account, organization: other_organization) }
  let_it_be(:banned_user) { create(:user, :banned, organization: other_organization) }
  let_it_be(:blocked_user) { create(:user, :blocked, organization: other_organization) }
  let_it_be(:ldap_blocked_user) { create(:user, :ldap_blocked, organization: other_organization) }
  let_it_be(:project_bot_user) { create(:user, :project_bot, organization: other_organization) }
  let_it_be(:internal_user) { create(:user, :support_bot, organization: other_organization) }

  subject(:finder) { described_class.new(organization: organization, current_user: current_user) }

  describe '#execute' do
    it 'excludes users who are already members of the organization' do
      expect(finder.execute).not_to include(existing_member)
    end

    it 'includes users who are only members of another organization', :aggregate_failures do
      expect(finder.execute).to include(invitable_user)
      expect(finder.execute).to include(external_user)
      expect(finder.execute).to include(unconfirmed_user)
      expect(finder.execute).to include(service_account_user)
    end

    it 'excludes users who cannot be invited', :aggregate_failures do
      expect(finder.execute).not_to include(banned_user)
      expect(finder.execute).not_to include(blocked_user)
      expect(finder.execute).not_to include(ldap_blocked_user)
      expect(finder.execute).not_to include(project_bot_user)
      expect(finder.execute).not_to include(internal_user)
    end

    it 'returns invitable users ordered by id descending' do
      invitable = [invitable_user, external_user, unconfirmed_user, service_account_user]

      expect(finder.execute.to_a & invitable).to eq(invitable.sort_by(&:id).reverse)
    end

    context 'when the user is a member of both organizations' do
      before do
        create(:organization_user, organization: organization, user: invitable_user)
      end

      it 'excludes the user' do
        expect(finder.execute).not_to include(invitable_user)
      end
    end

    context 'for search param' do
      subject(:finder) do
        described_class.new(organization: organization, current_user: current_user, search: search)
      end

      context 'when matching a name' do
        let(:search) { 'Zed Candidate' }

        it 'returns the matching user' do
          expect(finder.execute).to contain_exactly(invitable_user)
        end
      end

      context 'when matching a username' do
        let(:search) { 'zed-candidate' }

        it 'returns the matching user' do
          expect(finder.execute).to contain_exactly(invitable_user)
        end
      end

      context 'when matching an existing member' do
        let(:search) { 'zed-member' }

        it 'returns nothing' do
          expect(finder.execute).to be_empty
        end
      end

      context 'when nothing matches' do
        let(:search) { 'nonexistent-user' }

        it 'returns nothing' do
          expect(finder.execute).to be_empty
        end
      end
    end
  end
end
