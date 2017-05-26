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

    context 'subgroups' do
      let!(:parent_group) { create(:group, :public) }
      let!(:public_subgroup) { create(:group, :public, parent: parent_group) }
      let!(:internal_subgroup) { create(:group, :internal, parent: parent_group) }
      let!(:private_subgroup) { create(:group, :private, parent: parent_group) }

      context 'without a user' do
        it 'only returns public subgroups' do
          expect(described_class.new(nil, parent: parent_group).execute).to contain_exactly(public_subgroup)
        end
      end

      context 'with a user' do
        it 'returns public and internal subgroups' do
          expect(described_class.new(user, parent: parent_group).execute).to contain_exactly(public_subgroup, internal_subgroup)
        end

        context 'being member' do
          it 'returns public subgroups, internal subgroups, and private subgroups user is member of' do
            private_subgroup.add_guest(user)

            expect(described_class.new(user, parent: parent_group).execute).to contain_exactly(public_subgroup, internal_subgroup, private_subgroup)
          end
        end
      end
    end
  end
end
