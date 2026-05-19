# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteUsersFinder, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:user, :with_namespace) }
  let_it_be(:root_group) { create(:group) }

  let_it_be(:regular_user) { create(:user) }
  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be(:banned_user) { create(:user, :banned) }
  let_it_be(:blocked_user) { create(:user, :blocked) }
  let_it_be(:ldap_blocked_user) { create(:user, :ldap_blocked) }
  let_it_be(:external_user) { create(:user, :external) }
  let_it_be(:unconfirmed_user) { create(:user, confirmed_at: nil) }
  let_it_be(:omniauth_user) { create(:omniauth_user) }
  let_it_be(:internal_user) { Users::Internal.in_organization(current_user.organization).alert_bot }
  let_it_be(:project_bot_user) { create(:user, :project_bot) }
  let_it_be(:service_account_user) { create(:user, :service_account) }
  let(:organization) { current_user.organization }

  before_all do
    root_group.add_owner(current_user)
  end

  subject(:finder) do
    described_class.new(current_user, resource, organization_id: organization.id)
  end

  describe '#execute' do
    shared_examples 'searchable' do
      let(:searchable_users_ordered_by_id_desc) do
        [
          current_user,
          regular_user,
          admin_user,
          external_user,
          unconfirmed_user,
          omniauth_user,
          service_account_user
        ].sort_by(&:id).reverse
      end

      it 'returns searchable users ordered by id descending' do
        expect(finder.execute).to eq(searchable_users_ordered_by_id_desc)
      end

      context 'for search param' do
        subject(:finder) do
          described_class.new(current_user, resource, organization_id: organization.id, search: search)
        end

        context 'with empty string' do
          let(:search) { '' }

          it 'returns searchable users ordered by id descending' do
            expect(finder.execute).to eq(searchable_users_ordered_by_id_desc)
          end
        end

        context "with a user's name" do
          let(:search) { regular_user.name }

          it 'returns users that match the name' do
            expect(finder.execute).to eq([regular_user])
          end
        end
      end
    end

    context 'when scoping by organization' do
      let_it_be(:resource) { root_group }
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:other_user) { create(:user, organization: other_organization) }
      let(:organization) { other_organization }

      it 'scopes results correctly' do
        expect(finder.execute).to eq([other_user])
      end
    end

    context 'for root_group' do
      let_it_be(:resource) { root_group }

      include_examples 'searchable'
    end

    context 'for subgroup' do
      let_it_be(:subgroup) { create(:group, parent: root_group) }
      let_it_be(:resource) { subgroup }

      include_examples 'searchable'
    end

    context 'for project within group namespace' do
      let_it_be(:project) { create(:project, namespace: root_group, creator: current_user) }
      let_it_be(:resource) { project }

      include_examples 'searchable'
    end

    context 'for project within user namespace' do
      let_it_be(:project) { create(:project, namespace: current_user.namespace) }
      let_it_be(:resource) { project }

      include_examples 'searchable'
    end

    context 'when filtering ineligible service accounts' do
      let_it_be(:subgroup) { create(:group, parent: root_group) }
      let_it_be(:other_root) { create(:group) }
      let_it_be(:subgroup_sa) { create(:user, :service_account, provisioned_by_group: subgroup) }
      let_it_be(:project_in_root) { create(:project, namespace: root_group) }
      let_it_be(:project_sa) do
        create(:user, :service_account).tap do |user|
          user.user_detail.update!(provisioned_by_project_id: project_in_root.id)
        end
      end

      context 'when inviting to the root group' do
        let_it_be(:resource) { root_group }

        it 'excludes subgroup-provisioned SAs (cannot escape upward)' do
          expect(finder.execute).not_to include(subgroup_sa)
        end

        it 'excludes project-provisioned SAs (cannot escape to a group)' do
          expect(finder.execute).not_to include(project_sa)
        end
      end

      context 'when inviting to an unrelated group' do
        let_it_be(:resource) { other_root }

        before_all do
          other_root.add_owner(current_user)
        end

        it 'excludes subgroup-provisioned SAs from other hierarchies' do
          expect(finder.execute).not_to include(subgroup_sa)
        end
      end

      context 'when inviting to the origin subgroup' do
        let_it_be(:resource) { subgroup }

        it 'includes the subgroup-provisioned SA' do
          expect(finder.execute).to include(subgroup_sa)
        end
      end

      context 'when inviting to the origin project' do
        let_it_be(:resource) { project_in_root }

        it 'includes the project-provisioned SA' do
          expect(finder.execute).to include(project_sa)
        end
      end
    end
  end
end
