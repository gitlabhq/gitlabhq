# frozen_string_literal: true

require 'spec_helper'

describe GroupsFinder do
  describe '#execute' do
    let(:user) { create(:user) }

    describe 'root level groups' do
      using RSpec::Parameterized::TableSyntax

      where(:user_type, :params, :results) do
        nil | { all_available: true } | %i(public_group user_public_group)
        nil | { all_available: false } | %i(public_group user_public_group)
        nil | {} | %i(public_group user_public_group)

        :regular | { all_available: true } | %i(public_group internal_group user_public_group user_internal_group
                                                user_private_group)
        :regular | { all_available: false } | %i(user_public_group user_internal_group user_private_group)
        :regular | {} | %i(public_group internal_group user_public_group user_internal_group user_private_group)

        :external | { all_available: true } | %i(public_group user_public_group user_internal_group user_private_group)
        :external | { all_available: false } | %i(user_public_group user_internal_group user_private_group)
        :external | {} | %i(public_group user_public_group user_internal_group user_private_group)

        :admin | { all_available: true } | %i(public_group internal_group private_group user_public_group
                                              user_internal_group user_private_group)
        :admin | { all_available: false } | %i(user_public_group user_internal_group user_private_group)
        :admin | {} | %i(public_group internal_group private_group user_public_group user_internal_group
                         user_private_group)
      end

      with_them do
        before do
          # Fixme: Because of an issue: https://github.com/tomykaira/rspec-parameterized/issues/8#issuecomment-381888428
          # The groups need to be created here, not with let syntax, and also compared by name and not ids

          @groups = {
            private_group: create(:group, :private, name: 'private_group'),
            internal_group: create(:group, :internal, name: 'internal_group'),
            public_group: create(:group, :public, name: 'public_group'),

            user_private_group: create(:group, :private, name: 'user_private_group'),
            user_internal_group: create(:group, :internal, name: 'user_internal_group'),
            user_public_group: create(:group, :public, name: 'user_public_group')
          }

          if user_type
            user =
              case user_type
              when :regular
                create(:user)
              when :external
                create(:user, external: true)
              when :admin
                create(:user, :admin)
              end
            @groups.values_at(:user_private_group, :user_internal_group, :user_public_group).each do |group|
              group.add_developer(user)
            end
          end
        end

        subject { described_class.new(User.last, params).execute.to_a }

        it { is_expected.to match_array(@groups.values_at(*results)) }
      end
    end

    context 'subgroups' do
      let(:user) { create(:user) }
      let!(:parent_group) { create(:group, :public) }
      let!(:public_subgroup) { create(:group, :public, parent: parent_group) }
      let!(:internal_subgroup) { create(:group, :internal, parent: parent_group) }
      let!(:private_subgroup) { create(:group, :private, parent: parent_group) }

      context 'without a user' do
        it 'only returns parent and public subgroups' do
          expect(described_class.new(nil).execute).to contain_exactly(parent_group, public_subgroup)
        end
      end

      context 'with a user' do
        subject { described_class.new(user).execute }

        it 'returns parent, public, and internal subgroups' do
          is_expected.to contain_exactly(parent_group, public_subgroup, internal_subgroup)
        end

        context 'being member' do
          it 'returns parent, public subgroups, internal subgroups, and private subgroups user is member of' do
            private_subgroup.add_guest(user)

            is_expected.to contain_exactly(parent_group, public_subgroup, internal_subgroup, private_subgroup)
          end
        end

        context 'parent group private' do
          before do
            parent_group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          end

          context 'being member of parent group' do
            it 'returns all subgroups' do
              parent_group.add_guest(user)

              is_expected.to contain_exactly(parent_group, public_subgroup, internal_subgroup, private_subgroup)
            end
          end

          context 'authorized to private project' do
            context 'project one level deep' do
              let!(:subproject) { create(:project, :private, namespace: private_subgroup) }

              before do
                subproject.add_guest(user)
              end

              it 'includes the subgroup of the project' do
                is_expected.to include(private_subgroup)
              end

              it 'does not include private subgroups deeper down' do
                subsubgroup = create(:group, :private, parent: private_subgroup)

                is_expected.not_to include(subsubgroup)
              end
            end

            context 'project two levels deep' do
              let!(:private_subsubgroup) { create(:group, :private, parent: private_subgroup) }
              let!(:subsubproject) { create(:project, :private, namespace: private_subsubgroup) }

              before do
                subsubproject.add_guest(user)
              end

              it 'returns all the ancestor groups' do
                is_expected.to include(private_subsubgroup, private_subgroup, parent_group)
              end

              it 'returns the groups for a given parent' do
                expect(described_class.new(user, parent: parent_group).execute).to include(private_subgroup)
              end
            end
          end
        end
      end
    end
  end
end
