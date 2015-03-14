require 'spec_helper'

describe GroupsHelper do
  describe 'group_icon' do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it 'should return an url for the avatar' do
      group = create(:group)
      group.avatar = File.open(avatar_file_path)
      group.save!
      expect(group_icon(group.path).to_s).
        to match("/uploads/group/avatar/#{ group.id }/gitlab_logo.png")
    end

    it 'should give default avatar_icon when no avatar is present' do
      group = create(:group)
      group.save!
      expect(group_icon(group.path)).to match('group_avatar.png')
    end
  end
end
