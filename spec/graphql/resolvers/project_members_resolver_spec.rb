# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::ProjectMembersResolver do
  include GraphqlHelpers

  context "with a group" do
    let_it_be(:root_group)   { create(:group) }
    let_it_be(:group_1)      { create(:group, parent: root_group) }
    let_it_be(:group_2)      { create(:group, parent: root_group) }
    let_it_be(:project)      { create(:project, :public, group: group_1) }

    let_it_be(:user_1) { create(:user, name: 'test user') }
    let_it_be(:user_2) { create(:user, name: 'test user 2') }
    let_it_be(:user_3) { create(:user, name: 'another user 1') }
    let_it_be(:user_4) { create(:user, name: 'another user 2') }

    let_it_be(:project_member)    { create(:project_member, user: user_1, project: project) }
    let_it_be(:group_1_member)    { create(:group_member, user: user_2, group: group_1) }
    let_it_be(:group_2_member)    { create(:group_member, user: user_3, group: group_2) }
    let_it_be(:root_group_member) { create(:group_member, user: user_4, group: root_group) }

    let(:args) { {} }

    subject do
      resolve(described_class, obj: project, args: args, ctx: { context: user_4 })
    end

    describe '#resolve' do
      it 'finds all project members' do
        expect(subject).to contain_exactly(project_member, group_1_member, root_group_member)
      end

      context 'with search' do
        context 'when the search term matches a user' do
          let(:args) { { search: 'test' } }

          it 'searches users by user name' do
            expect(subject).to contain_exactly(project_member, group_1_member)
          end
        end

        context 'when the search term does not match any user' do
          let(:args) { { search: 'nothing' } }

          it 'is empty' do
            expect(subject).to be_empty
          end
        end
      end

      context 'when project is nil' do
        let(:project) { nil }

        it 'returns nil' do
          expect(subject).to be_empty
        end
      end
    end
  end
end
