# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersFinder do
  describe '#execute' do
    include_context 'UsersFinder#execute filter by project context'

    context 'with a normal user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'executes users finder as normal user'

      context 'with group argument is passed' do
        let_it_be(:group) { create(:group, :private) }
        let_it_be(:subgroup) { create(:group, :private, parent: group) }
        let_it_be(:not_group_member) { create(:user) }

        let_it_be(:indirect_group_member) do
          create(:user, developer_of: subgroup)
        end

        let_it_be(:direct_group_members) do
          [user, omniauth_user, internal_user].each { |u| group.add_developer(u) }
        end

        it 'filtered by search' do
          users = described_class.new(user, group: group).execute
          expect(users).to contain_exactly(indirect_group_member, *direct_group_members)
        end

        context 'when user cannot read group' do
          it 'filtered by search' do
            expect { described_class.new(not_group_member, group: group).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end
      end
    end

    context 'with no current_user' do
      it 'ignores the admins param' do
        users = described_class.new(nil, admins: true, username: normal_user.username).execute

        expect(users).to contain_exactly(normal_user)
      end

      it 'searches without matching private emails' do
        users = described_class.new(nil, search: normal_user.email).execute

        expect(users).to be_empty
      end
    end

    context 'with an admin user' do
      let_it_be(:user) { create(:admin) }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it_behaves_like 'executes users finder as admin'
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it_behaves_like 'executes users finder as admin'
        end

        context 'when not in admin mode' do
          it_behaves_like 'executes users finder as normal user'
        end
      end
    end
  end
end
