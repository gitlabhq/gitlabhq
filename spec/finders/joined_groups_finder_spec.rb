require 'spec_helper'

describe JoinedGroupsFinder do
  describe '#execute' do
    let!(:profile_owner)    { create(:user) }
    let!(:profile_visitor)  { create(:user) }

    let!(:private_group)    { create(:group, :private) }
    let!(:private_group_2)  { create(:group, :private) }
    let!(:internal_group)   { create(:group, :internal) }
    let!(:internal_group_2) { create(:group, :internal) }
    let!(:public_group)     { create(:group, :public) }
    let!(:public_group_2)   { create(:group, :public) }
    let!(:finder) { described_class.new(profile_owner) }

    context 'without a user' do
      before do
        public_group.add_master(profile_owner)
      end

      it 'only shows public groups from profile owner' do
        expect(finder.execute).to eq([public_group])
      end
    end

    context "with a user" do
      before do
        private_group.add_master(profile_owner)
        internal_group.add_master(profile_owner)
        public_group.add_master(profile_owner)
      end

      context "when the profile visitor is in the private group" do
        before do
          private_group.add_developer(profile_visitor)
        end

        it 'only shows groups where both users are authorized to see' do
          expect(finder.execute(profile_visitor)).to eq([public_group, internal_group, private_group])
        end
      end

      context 'if profile visitor is in one of the private group projects' do
        before do
          project = create(:project, :private, group: private_group, name: 'B', path: 'B')
          project.add_user(profile_visitor, Gitlab::Access::DEVELOPER)
        end

        it 'shows group' do
          expect(finder.execute(profile_visitor)).to eq([public_group, internal_group, private_group])
        end
      end

      context 'external users' do
        before do
          profile_visitor.update_attributes(external: true)
        end

        context 'if not a member' do
          it "does not show internal groups" do
            expect(finder.execute(profile_visitor)).to eq([public_group])
          end
        end

        context "if authorized" do
          before do
            internal_group.add_master(profile_visitor)
          end

          it "shows internal groups if authorized" do
            expect(finder.execute(profile_visitor)).to eq([public_group, internal_group])
          end
        end
      end
    end
  end
end
