# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsHelper do
  include ApplicationHelper
  include AvatarsHelper

  describe '#group_icon_url' do
    it 'returns an url for the avatar' do
      group = create(:group, :with_avatar)

      expect(group_icon_url(group.path).to_s).to match(group.avatar.url)
    end

    it 'gives default avatar_icon when no avatar is present' do
      group = build_stubbed(:group)

      expect(group_icon_url(group.path)).to match_asset_path('group_avatar.png')
    end
  end

  describe '#group_lfs_status' do
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, namespace_id: group.id) }

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
      let_it_be_with_reload(:another_project) { create(:project, namespace_id: group.id) }

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

  describe '#group_title' do
    let_it_be(:group) { create(:group) }
    let_it_be(:nested_group) { create(:group, parent: group) }
    let_it_be(:deep_nested_group) { create(:group, parent: nested_group) }
    let_it_be(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    subject { helper.group_title(very_deep_nested_group) }

    context 'traversal queries' do
      shared_examples 'correct ancestor order' do
        it 'outputs the groups in the correct order' do
          expect(subject)
            .to match(%r{<li><a.*>#{deep_nested_group.name}.*</li>.*<a.*>#{very_deep_nested_group.name}</a>}m)
        end
      end

      context 'recursive' do
        before do
          stub_feature_flags(use_traversal_ids: false)
        end

        include_examples 'correct ancestor order'
      end

      context 'linear' do
        before do
          stub_feature_flags(use_traversal_ids: true)

          very_deep_nested_group.reload # make sure traversal_ids are reloaded
        end

        include_examples 'correct ancestor order'
      end
    end

    it 'enqueues the elements in the breadcrumb schema list' do
      expect(helper).to receive(:push_to_schema_breadcrumb).with(group.name, group_path(group))
      expect(helper).to receive(:push_to_schema_breadcrumb).with(nested_group.name, group_path(nested_group))
      expect(helper).to receive(:push_to_schema_breadcrumb).with(deep_nested_group.name, group_path(deep_nested_group))
      expect(helper).to receive(:push_to_schema_breadcrumb).with(very_deep_nested_group.name, group_path(very_deep_nested_group))

      subject
    end

    it 'avoids N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        helper.group_title(nested_group)
      end

      expect do
        helper.group_title(very_deep_nested_group)
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe '#group_title_link' do
    let_it_be(:group) { create(:group, :with_avatar) }

    let(:raw_link) { group_title_link(group, show_avatar: true) }
    let(:document) { Nokogiri::HTML.parse(raw_link) }

    describe 'link' do
      subject(:link) { document.css('.group-path').first }

      it 'uses the group name as innerText' do
        expect(link.inner_text).to eq(group.name)
      end

      it 'links to the group path' do
        expect(link.attr('href')).to eq(group_path(group))
      end
    end

    describe 'icon' do
      subject(:icon) { document.css('.avatar-tile').first }

      it 'specifies the group name as the alt text' do
        expect(icon.attr('alt')).to eq(group.name)
      end

      it 'uses the group\'s avatar_url' do
        expect(icon.attr('src')).to eq(group.avatar_url)
      end
    end
  end

  describe '#share_with_group_lock_help_text' do
    context 'traversal queries' do
      let_it_be_with_reload(:root_group) { create(:group) }
      let_it_be_with_reload(:subgroup) { create(:group, parent: root_group) }
      let_it_be_with_reload(:sub_subgroup) { create(:group, parent: subgroup) }
      let_it_be(:root_owner) { create(:user) }
      let_it_be(:sub_owner) { create(:user) }
      let_it_be(:sub_sub_owner) { create(:user) }

      let(:possible_help_texts) do
        {
          default_help: "Applied to all subgroups unless overridden by a group owner.",
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

      before_all do
        root_group.add_owner(root_owner)
        subgroup.add_owner(sub_owner)
        sub_subgroup.add_owner(sub_sub_owner)
      end

      shared_examples 'correct ancestor order' do
        # rubocop:disable Layout/SpaceBeforeComma
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
        # rubocop:enable Layout/SpaceBeforeComma

        with_them do
          before do
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

      context 'recursive' do
        before do
          stub_feature_flags(use_traversal_ids: false)
        end

        include_examples 'correct ancestor order'
      end

      context 'linear' do
        before do
          stub_feature_flags(use_traversal_ids: true)
        end

        include_examples 'correct ancestor order'
      end
    end
  end

  describe '#can_disable_group_emails?' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group, name: 'group') }
    let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: group) }

    before do
      allow(helper).to receive(:current_user) { current_user }
    end

    it 'returns true for the group owner' do
      allow(helper).to receive(:can?).with(current_user, :set_emails_disabled, group) { true }

      expect(helper.can_disable_group_emails?(group)).to be_truthy
    end

    it 'returns false for anyone else' do
      allow(helper).to receive(:can?).with(current_user, :set_emails_disabled, group) { false }

      expect(helper.can_disable_group_emails?(group)).to be_falsey
    end

    context 'when subgroups' do
      before do
        allow(helper).to receive(:can?).with(current_user, :set_emails_disabled, subgroup) { true }
      end

      it 'returns false if parent group is disabling emails' do
        allow(group).to receive(:emails_disabled?).and_return(true)

        expect(helper.can_disable_group_emails?(subgroup)).to be_falsey
      end

      it 'returns true if parent group is not disabling emails' do
        allow(group).to receive(:emails_disabled?).and_return(false)

        expect(helper.can_disable_group_emails?(subgroup)).to be_truthy
      end
    end
  end

  describe '#can_update_default_branch_protection?' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group) }

    subject { helper.can_update_default_branch_protection?(group) }

    before do
      allow(helper).to receive(:current_user) { current_user }
    end

    context 'for users who can update default branch protection of the group' do
      before do
        allow(helper).to receive(:can?).with(current_user, :update_default_branch_protection, group) { true }
      end

      it { is_expected.to be_truthy }
    end

    context 'for users who cannot update default branch protection of the group' do
      before do
        allow(helper).to receive(:can?).with(current_user, :update_default_branch_protection, group) { false }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#show_thanks_for_purchase_alert?' do
    subject { helper.show_thanks_for_purchase_alert?(quantity) }

    context 'with quantity present' do
      let(:quantity) { 1 }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'with quantity not present' do
      let(:quantity) { nil }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'with quantity empty' do
      let(:quantity) { '' }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#render_setting_to_allow_project_access_token_creation?' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }

    before do
      allow(helper).to receive(:current_user) { current_user }
      parent.add_owner(current_user)
      group.add_owner(current_user)
    end

    it 'returns true if group is root' do
      expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to be_truthy
    end

    it 'returns false if group is subgroup' do
      expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsy
    end
  end

  describe '#can_admin_group_member?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    it 'returns true when current_user can admin members' do
      group.add_owner(user)

      expect(helper.can_admin_group_member?(group)).to be(true)
    end

    it 'returns false when current_user can not admin members' do
      expect(helper.can_admin_group_member?(group)).to be(false)
    end
  end

  describe '#localized_jobs_to_be_done_choices' do
    it 'has a translation for all `jobs_to_be_done` values' do
      expect(localized_jobs_to_be_done_choices.keys).to match_array(NamespaceSetting.jobs_to_be_dones.keys)
    end
  end

  describe '#subgroup_creation_data' do
    let_it_be(:name) { 'parent group' }
    let_it_be(:group) { build(:group, name: name) }
    let_it_be(:subgroup) { build(:group, parent: group) }

    context 'when group has a parent' do
      it 'returns expected hash' do
        expect(subgroup_creation_data(subgroup)).to eq({
          import_existing_group_path: '/groups/new#import-group-pane',
          parent_group_name: name,
          parent_group_url: group_url(group)
        })
      end
    end

    context 'when group does not have a parent' do
      it 'returns expected hash' do
        expect(subgroup_creation_data(group)).to eq({
          import_existing_group_path: '/groups/new#import-group-pane',
          parent_group_name: nil,
          parent_group_url: nil
        })
      end
    end
  end

  describe '#group_name_and_path_app_data' do
    let_it_be(:root_url) { 'https://gitlab.com/' }

    before do
      allow(Gitlab.config.mattermost).to receive(:enabled).and_return(true)
      allow(helper).to receive(:root_url) { root_url }
    end

    context 'when group has a parent' do
      it 'returns expected hash' do
        expect(group_name_and_path_app_data).to match({
          base_path: 'https://gitlab.com/',
          mattermost_enabled: 'true'
        })
      end
    end
  end

  describe '#group_overview_tabs_app_data' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:initial_sort) { 'created_asc' }

    before do
      allow(helper).to receive(:current_user).and_return(user)

      allow(helper).to receive(:can?).with(user, :create_subgroup, group) { true }
      allow(helper).to receive(:can?).with(user, :create_projects, group) { true }
      allow(helper).to receive(:project_list_sort_by).and_return(initial_sort)
    end

    it 'returns expected hash' do
      expect(helper.group_overview_tabs_app_data(group)).to match(
        {
          subgroups_and_projects_endpoint: including("/groups/#{group.path}/-/children.json"),
          shared_projects_endpoint: including("/groups/#{group.path}/-/shared_projects.json"),
          archived_projects_endpoint: including("/groups/#{group.path}/-/children.json?archived=only"),
          current_group_visibility: group.visibility,
          initial_sort: initial_sort,
          show_schema_markup: 'true',
          new_subgroup_path: including("groups/new?parent_id=#{group.id}#create-group-pane"),
          new_project_path: including("/projects/new?namespace_id=#{group.id}"),
          new_subgroup_illustration: including('illustrations/subgroup-create-new-sm'),
          new_project_illustration: including('illustrations/project-create-new-sm'),
          empty_projects_illustration: including('illustrations/empty-state/empty-projects-md'),
          empty_subgroup_illustration: including('illustrations/empty-state/empty-subgroup-md'),
          render_empty_state: 'true',
          can_create_subgroups: 'true',
          can_create_projects: 'true'
        }
      )
    end
  end

  describe "#enabled_git_access_protocol_options_for_group" do
    subject { helper.enabled_git_access_protocol_options_for_group }

    before do
      expect(::Gitlab::CurrentSettings).to receive(:enabled_git_access_protocol).and_return(instance_setting)
    end

    context "instance setting is nil" do
      let(:instance_setting) { nil }

      it { is_expected.to contain_exactly([_("Both SSH and HTTP(S)"), "all"], [_("Only SSH"), "ssh"], [_("Only HTTP(S)"), "http"]) }
    end

    context "instance setting is blank" do
      let(:instance_setting) { nil }

      it { is_expected.to contain_exactly([_("Both SSH and HTTP(S)"), "all"], [_("Only SSH"), "ssh"], [_("Only HTTP(S)"), "http"]) }
    end

    context "instance setting is ssh" do
      let(:instance_setting) { "ssh" }

      it { is_expected.to contain_exactly([_("Only SSH"), "ssh"]) }
    end

    context "instance setting is http" do
      let(:instance_setting) { "http" }

      it { is_expected.to contain_exactly([_("Only HTTP(S)"), "http"]) }
    end
  end
end
