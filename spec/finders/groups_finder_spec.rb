require 'spec_helper'

describe GroupsFinder do
  describe '#execute' do
    let(:user)            { create(:user) }

    context 'root level groups' do
      let!(:private_group)  { create(:group, :private) }
      let!(:internal_group) { create(:group, :internal) }
      let!(:public_group)   { create(:group, :public) }

      context 'without a user' do
        subject { described_class.new.execute }

        it { is_expected.to eq([public_group]) }
      end

      context 'with a user' do
        subject { described_class.new(user).execute }

        context 'normal user' do
          it { is_expected.to contain_exactly(public_group, internal_group) }
        end

        context 'external user' do
          let(:user) { create(:user, external: true) }

          it { is_expected.to contain_exactly(public_group) }
        end

        context 'user is member of the private group' do
          before do
            private_group.add_guest(user)
          end

          it { is_expected.to contain_exactly(public_group, internal_group, private_group) }
        end
      end
    end

    context 'subgroups', :nested_groups do
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
