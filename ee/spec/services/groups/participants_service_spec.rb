require 'spec_helper'

describe Groups::ParticipantsService do
  let(:group) { create(:group, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png')) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group, author: user) }

  before do
    create(:group_member, group: group, user: user)
  end

  def user_to_autocompletable(user)
    {
      username: user.username,
      name: user.name,
      avatar_url: user.avatar_url
    }
  end

  describe '#execute' do
    it 'should add the owner to the list' do
      expect(described_class.new(group, user).execute(epic).first).to eq(user_to_autocompletable(user))
    end
  end

  describe '#participants_in_noteable' do
    before do
      @users = []
      5.times do
        other_user = create(:user)
        create(:group_member, group: group, user: other_user)
        @users << other_user
      end

      create(:note, author: user, project: nil, noteable: epic, note: @users.map { |u| u.to_reference }.join(' '))
    end

    it 'should return all participants' do
      service = described_class.new(group, user)
      service.instance_variable_set(:@noteable, epic)
      result = service.participants_in_noteable

      expected_users = (@users + [user]).map(&method(:user_to_autocompletable))

      expect(result).to match_array(expected_users)
    end
  end

  describe '#group_members', :nested_groups do
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:subgroup) { create(:group_with_members, parent: group) }
    let(:subproject) { create(:project, group: subgroup) }

    it 'should return all members in parent groups, sub-groups, and sub-projects' do
      parent_group.add_developer(create(:user))
      subgroup.add_developer(create(:user))
      subproject.add_developer(create(:user))

      service = described_class.new(group, user)
      service.instance_variable_set(:@noteable, epic)
      result = service.group_members

      expected_users = (group.self_and_hierarchy.map(&:users).flatten + subproject.users)
                       .map(&method(:user_to_autocompletable))

      expect(expected_users.count).to eq(5)
      expect(result).to match_array(expected_users)
    end
  end

  describe '#groups' do
    describe 'avatar_url' do
      let(:groups) { described_class.new(group, user).groups }

      it 'should return an url for the avatar' do
        expect(groups.size).to eq 1
        expect(groups.first[:avatar_url]).to eq("/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end

      it 'should return an url for the avatar with relative url' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        expect(groups.size).to eq 1
        expect(groups.first[:avatar_url]).to eq("/gitlab/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end
    end
  end
end
