require 'spec_helper'

describe GroupsHelper do
  include ApplicationHelper

  describe 'group_icon' do
    avatar_file_path = File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')

    it 'returns an url for the avatar' do
      group = create(:group)
      group.avatar = fixture_file_upload(avatar_file_path)
      group.save!

      expect(helper.group_icon(group).to_s)
        .to eq "<img data-src=\"#{group.avatar.url}\" class=\" lazy\" src=\"#{LazyImageTagHelper.placeholder_image}\" />"
    end
  end

  describe 'group_icon_url' do
    avatar_file_path = File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')

    it 'returns an url for the avatar' do
      group = create(:group)
      group.avatar = fixture_file_upload(avatar_file_path)
      group.save!
      expect(group_icon_url(group.path).to_s)
        .to match(group.avatar.url)
    end

    it 'gives default avatar_icon when no avatar is present' do
      group = create(:group)
      group.save!
      expect(group_icon_url(group.path)).to match_asset_path('group_avatar.png')
    end
  end

  describe 'group_lfs_status' do
    let(:group) { create(:group) }
    let!(:project) { create(:project, namespace_id: group.id) }

    before do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
    end

    context 'only one project in group' do
      before do
        group.update_attribute(:lfs_enabled, true)
      end

      it 'returns all projects as enabled' do
        expect(group_lfs_status(group)).to include('Enabled for all projects')
      end

      it 'returns all projects as disabled' do
        project.update_attribute(:lfs_enabled, false)

        expect(group_lfs_status(group)).to include('Enabled for 0 out of 1 project')
      end
    end

    context 'more than one project in group' do
      before do
        create(:project, namespace_id: group.id)
      end

      context 'LFS enabled in group' do
        before do
          group.update_attribute(:lfs_enabled, true)
        end

        it 'returns both projects as enabled' do
          expect(group_lfs_status(group)).to include('Enabled for all projects')
        end

        it 'returns only one as enabled' do
          project.update_attribute(:lfs_enabled, false)

          expect(group_lfs_status(group)).to include('Enabled for 1 out of 2 projects')
        end
      end

      context 'LFS disabled in group' do
        before do
          group.update_attribute(:lfs_enabled, false)
        end

        it 'returns both projects as disabled' do
          expect(group_lfs_status(group)).to include('Disabled for all projects')
        end

        it 'returns only one as disabled' do
          project.update_attribute(:lfs_enabled, true)

          expect(group_lfs_status(group)).to include('Disabled for 1 out of 2 projects')
        end
      end
    end
  end

  describe 'group_title', :nested_groups do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'outputs the groups in the correct order' do
      expect(helper.group_title(very_deep_nested_group))
        .to match(%r{<li style="text-indent: 16px;"><a.*>#{deep_nested_group.name}.*</li>.*<a.*>#{very_deep_nested_group.name}</a>}m)
    end
  end

  # rubocop:disable Layout/SpaceBeforeComma
  describe '#share_with_group_lock_help_text', :nested_groups do
    let!(:root_group) { create(:group) }
    let!(:subgroup) { create(:group, parent: root_group) }
    let!(:sub_subgroup) { create(:group, parent: subgroup) }
    let(:root_owner) { create(:user) }
    let(:sub_owner) { create(:user) }
    let(:sub_sub_owner) { create(:user) }
    let(:possible_help_texts) do
      {
        default_help: "This setting will be applied to all subgroups unless overridden by a group owner",
        ancestor_locked_but_you_can_override: %r{This setting is applied on <a .+>.+</a>\. You can override the setting or .+},
        ancestor_locked_so_ask_the_owner: /This setting is applied on .+\. To share projects in this group with another group, ask the owner to override the setting or remove the share with group lock from .+/,
        ancestor_locked_and_has_been_overridden: /This setting is applied on .+ and has been overridden on this subgroup/
      }
    end
    let(:possible_linked_ancestors) do
      {
        root_group: root_group,
        subgroup: subgroup
      }
    end
    let(:users) do
      {
        root_owner: root_owner,
        sub_owner: sub_owner,
        sub_sub_owner: sub_sub_owner
      }
    end
    subject { helper.share_with_group_lock_help_text(sub_subgroup) }

    where(:root_share_with_group_locked, :subgroup_share_with_group_locked, :sub_subgroup_share_with_group_locked, :current_user, :help_text, :linked_ancestor) do
      [
        [false , false , false , :root_owner     , :default_help                            , nil],
        [false , false , false , :sub_owner      , :default_help                            , nil],
        [false , false , false , :sub_sub_owner  , :default_help                            , nil],
        [false , false , true  , :root_owner     , :default_help                            , nil],
        [false , false , true  , :sub_owner      , :default_help                            , nil],
        [false , false , true  , :sub_sub_owner  , :default_help                            , nil],
        [false , true  , false , :root_owner     , :ancestor_locked_and_has_been_overridden , :subgroup],
        [false , true  , false , :sub_owner      , :ancestor_locked_and_has_been_overridden , :subgroup],
        [false , true  , false , :sub_sub_owner  , :ancestor_locked_and_has_been_overridden , :subgroup],
        [false , true  , true  , :root_owner     , :ancestor_locked_but_you_can_override    , :subgroup],
        [false , true  , true  , :sub_owner      , :ancestor_locked_but_you_can_override    , :subgroup],
        [false , true  , true  , :sub_sub_owner  , :ancestor_locked_so_ask_the_owner        , :subgroup],
        [true  , false , false , :root_owner     , :default_help                            , nil],
        [true  , false , false , :sub_owner      , :default_help                            , nil],
        [true  , false , false , :sub_sub_owner  , :default_help                            , nil],
        [true  , false , true  , :root_owner     , :default_help                            , nil],
        [true  , false , true  , :sub_owner      , :default_help                            , nil],
        [true  , false , true  , :sub_sub_owner  , :default_help                            , nil],
        [true  , true  , false , :root_owner     , :ancestor_locked_and_has_been_overridden , :root_group],
        [true  , true  , false , :sub_owner      , :ancestor_locked_and_has_been_overridden , :root_group],
        [true  , true  , false , :sub_sub_owner  , :ancestor_locked_and_has_been_overridden , :root_group],
        [true  , true  , true  , :root_owner     , :ancestor_locked_but_you_can_override    , :root_group],
        [true  , true  , true  , :sub_owner      , :ancestor_locked_so_ask_the_owner        , :root_group],
        [true  , true  , true  , :sub_sub_owner  , :ancestor_locked_so_ask_the_owner        , :root_group]
      ]
    end

    with_them do
      before do
        root_group.add_owner(root_owner)
        subgroup.add_owner(sub_owner)
        sub_subgroup.add_owner(sub_sub_owner)

        root_group.update_column(:share_with_group_lock, true) if root_share_with_group_locked
        subgroup.update_column(:share_with_group_lock, true) if subgroup_share_with_group_locked
        sub_subgroup.update_column(:share_with_group_lock, true) if sub_subgroup_share_with_group_locked

        allow(helper).to receive(:current_user).and_return(users[current_user])
        allow(helper).to receive(:can?)
                           .with(users[current_user], :change_share_with_group_lock, subgroup)
                           .and_return(Ability.allowed?(users[current_user], :change_share_with_group_lock, subgroup))

        ancestor = possible_linked_ancestors[linked_ancestor]
        if ancestor
          allow(helper).to receive(:can?)
                             .with(users[current_user], :read_group, ancestor)
                             .and_return(Ability.allowed?(users[current_user], :read_group, ancestor))
          allow(helper).to receive(:can?)
                             .with(users[current_user], :admin_group, ancestor)
                             .and_return(Ability.allowed?(users[current_user], :admin_group, ancestor))
        end
      end

      it 'has the correct help text with correct ancestor links' do
        expect(subject).to match(possible_help_texts[help_text])
        expect(subject).to match(possible_linked_ancestors[linked_ancestor].name) unless help_text == :default_help
      end
    end
  end

  describe '#group_sidebar_links' do
    let(:group) { create(:group, :public) }
    let(:user) { create(:user) }
    before do
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?) { true }
      helper.instance_variable_set(:@group, group)
    end

    it 'returns all the expected links' do
      links = [
        :overview, :activity, :issues, :labels, :milestones, :merge_requests,
        :group_members, :settings
      ]

      expect(helper.group_sidebar_links).to include(*links)
    end

    it 'includes settings when the user can admin the group' do
      expect(helper).to receive(:current_user) { user }
      expect(helper).to receive(:can?).with(user, :admin_group, group) { false }

      expect(helper.group_sidebar_links).not_to include(:settings)
    end

    it 'excludes cross project features when the user cannot read cross project' do
      cross_project_features = [:activity, :issues, :labels, :milestones,
                                :merge_requests]

      expect(helper).to receive(:can?).with(user, :read_cross_project) { false }

      expect(helper.group_sidebar_links).not_to include(*cross_project_features)
    end
  end
end
