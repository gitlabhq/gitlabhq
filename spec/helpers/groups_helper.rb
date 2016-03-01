require 'spec_helper'

describe GroupsHelper do
  describe 'group_icon' do
    avatar_file_path = File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')

    it 'should return an url for the avatar' do
      group = create(:group)
      group.avatar = File.open(avatar_file_path)
      group.save!
      expect(group_icon(group.path).to_s).
        to match("/uploads/group/avatar/#{group.id}/banana_sample.gif")
    end

    it 'should give default avatar_icon when no avatar is present' do
      group = create(:group)
      group.save!
      expect(group_icon(group.path)).to match('group_avatar.png')
    end
  end

  describe 'permissions' do
    let(:group) { create(:group) }
    let!(:user)  { create(:user) }

    before do
      allow(self).to receive(:current_user).and_return(user)
      allow(self).to receive(:can?) { true }
    end

    it 'checks user ability to change permissions' do
      expect(self).to receive(:can?).with(user, :change_visibility_level, group)
      can_change_group_visibility_level?(group)
    end
  end
end
