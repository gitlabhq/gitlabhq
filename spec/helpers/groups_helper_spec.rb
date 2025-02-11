# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsHelper, feature_category: :groups_and_projects do
  include ApplicationHelper
  include AvatarsHelper
  include NumbersHelper

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
            .to match(%r{<li.*><a.*>#{deep_nested_group.name}.*</li>.*<a.*>#{very_deep_nested_group.name}</a>}m)
        end
      end

      before do
        very_deep_nested_group.reload # make sure traversal_ids are reloaded
      end

      include_examples 'correct ancestor order'
    end

    it 'enqueues the elements in the breadcrumb schema list' do
      expect(helper).to receive(:push_to_schema_breadcrumb).with(group.name, group_path(group), nil)
      expect(helper).to receive(:push_to_schema_breadcrumb).with(nested_group.name, group_path(nested_group), nil)
      expect(helper).to receive(:push_to_schema_breadcrumb).with(deep_nested_group.name, group_path(deep_nested_group), nil)
      expect(helper).to receive(:push_to_schema_breadcrumb).with(very_deep_nested_group.name, group_path(very_deep_nested_group), nil)

      subject
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new do
        helper.group_title(nested_group)
      end

      expect do
        helper.group_title(very_deep_nested_group)
      end.not_to exceed_query_limit(control)
    end
  end

  describe '#group_title_link' do
    let_it_be(:group) { create(:group, :with_avatar) }

    let(:raw_link) { group_title_link(group, show_avatar: true) }
    let(:document) { Nokogiri::HTML.parse(raw_link) }

    describe 'link' do
      subject(:link) { document.css('.group-path').first }

      it 'uses the group name as innerText' do
        expect(link.inner_text).to match(group.name)
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
        expect(icon.attr('src')).to match(group.avatar_url)
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

      include_examples 'correct ancestor order'
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
        allow(group).to receive(:emails_enabled?).and_return(false)

        expect(helper.can_disable_group_emails?(subgroup)).to be_falsey
      end

      it 'returns true if parent group is not disabling emails' do
        allow(group).to receive(:emails_enabled?).and_return(true)

        expect(helper.can_disable_group_emails?(subgroup)).to be_truthy
      end
    end
  end

  describe '#can_set_group_diff_preview_in_email?' do
    let_it_be(:group) { create(:group, name: 'group') }
    let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: group) }

    let_it_be(:current_user) { create(:user) }
    let_it_be(:group_owner)  { create(:group_member, :owner, group: group, user: create(:user)).user }
    let_it_be(:group_maintainer) { create(:group_member, :maintainer, group: group, user: create(:user)).user }

    before do
      group.update_attribute(:show_diff_preview_in_email, true)
    end

    it 'returns true for an owner of the group' do
      allow(helper).to receive(:current_user) { group_owner }

      expect(helper.can_set_group_diff_preview_in_email?(group)).to be_truthy
    end

    it 'returns false for a maintainer of the group' do
      allow(helper).to receive(:current_user) { group_maintainer }

      expect(helper.can_set_group_diff_preview_in_email?(group)).to be_falsey
    end

    it 'returns false for anyone else' do
      allow(helper).to receive(:current_user) { current_user }

      expect(helper.can_set_group_diff_preview_in_email?(group)).to be_falsey
    end

    context 'respects the settings of a parent group' do
      context 'when a parent group has disabled diff previews ' do
        before do
          group.update_attribute(:show_diff_preview_in_email, false)
        end

        it 'returns false for all users' do
          allow(helper).to receive(:current_user) { group_owner }
          expect(helper.can_set_group_diff_preview_in_email?(subgroup)).to be_falsey

          allow(helper).to receive(:current_user) { group_maintainer }
          expect(helper.can_set_group_diff_preview_in_email?(subgroup)).to be_falsey

          allow(helper).to receive(:current_user) { current_user }
          expect(helper.can_set_group_diff_preview_in_email?(subgroup)).to be_falsey
        end
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
    let_it_be(:user) { build(:user) }
    let_it_be(:group) { build(:group, name: name) }
    let_it_be(:subgroup) { build(:group, parent: group) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    context 'when group has a parent' do
      it 'returns expected hash' do
        expect(helper.subgroup_creation_data(subgroup)).to include({
          import_existing_group_path: '/groups/new#import-group-pane',
          parent_group_name: name,
          parent_group_url: group_url(group),
          is_saas: 'false'
        })
      end
    end

    context 'when group does not have a parent' do
      it 'returns expected hash' do
        expect(helper.subgroup_creation_data(group)).to include({
          import_existing_group_path: '/groups/new#import-group-pane',
          parent_group_name: nil,
          parent_group_url: nil,
          is_saas: 'false'
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
          group_id: group.id,
          subgroups_and_projects_endpoint: including("/groups/#{group.path}/-/children.json"),
          shared_projects_endpoint: including("/groups/#{group.path}/-/shared_projects.json"),
          inactive_projects_endpoint: including("/groups/#{group.path}/-/children.json?archived=only"),
          current_group_visibility: group.visibility,
          initial_sort: initial_sort,
          show_schema_markup: 'true',
          new_subgroup_path: including("groups/new?parent_id=#{group.id}#create-group-pane"),
          new_project_path: including("/projects/new?namespace_id=#{group.id}"),
          empty_projects_illustration: including('illustrations/empty-state/empty-projects-md'),
          empty_subgroup_illustration: including('illustrations/empty-state/empty-projects-md'),
          render_empty_state: 'true',
          can_create_subgroups: 'true',
          can_create_projects: 'true'
        }
      )
    end
  end

  describe '#show_group_readme?' do
    let_it_be_with_refind(:group) { create(:group, :public) }
    let_it_be(:current_user) { nil }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'when project is public' do
      let_it_be(:project) { create(:project, :public, :readme, group: group, path: 'gitlab-profile') }

      it { expect(helper.show_group_readme?(group)).to be(true) }
    end

    context 'when project is private' do
      let_it_be(:project) { create(:project, :private, :readme, group: group, path: 'gitlab-profile') }

      context 'when user can see the project' do
        let_it_be(:current_user) { create(:user) }

        before do
          project.add_developer(current_user)
        end

        it { expect(helper.show_group_readme?(group)).to be(true) }
      end

      it 'when user can not see the project' do
        expect(helper.show_group_readme?(group)).to be(false)
      end
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

  describe '#new_custom_emoji_path' do
    subject { helper.new_custom_emoji_path(group) }

    let_it_be(:group) { create(:group) }

    context 'with nil group' do
      let(:group) { nil }

      it { is_expected.to eq(nil) }
    end

    context 'with current_user who has no permissions' do
      before do
        allow(helper).to receive(:current_user).and_return(create(:user))
      end

      it { is_expected.to eq(nil) }
    end

    context 'with current_user who has permissions' do
      before do
        user = create(:user)
        group.add_owner(user)
        allow(helper).to receive(:current_user).and_return(user)
      end

      it { is_expected.to eq(new_group_custom_emoji_path(group)) }
    end
  end

  describe '#access_level_roles_user_can_assign' do
    subject { helper.access_level_roles_user_can_assign(group, group.access_level_roles) }

    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }

    context 'when user is provided' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when a user is a group member' do
        before do
          group.add_developer(user)
        end

        it 'returns only the roles the provided user can assign' do
          expect(subject).to eq(
            {
              'Guest' => 10,
              'Planner' => 15,
              'Reporter' => 20,
              'Developer' => 30
            }
          )
        end
      end

      context 'when a user is an admin', :enable_admin_mode do
        before do
          user.update!(admin: true)
        end

        it 'returns all roles' do
          expect(subject).to eq(
            {
              'Guest' => 10,
              'Planner' => 15,
              'Reporter' => 20,
              'Developer' => 30,
              'Maintainer' => 40,
              'Owner' => 50
            }
          )
        end
      end

      context 'when a user is not a group member' do
        it 'returns the empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when a user has different access for different groups in the hierarchy' do
        let_it_be(:grand_parent) { create(:group) }
        let_it_be(:parent) { create(:group, parent: grand_parent) }
        let_it_be(:child) { create(:group, parent: parent) }
        let_it_be(:grand_child) { create(:group, parent: child) }

        before_all do
          parent.add_developer(user)
          child.add_maintainer(user)
          grand_child.add_owner(user)
        end

        it 'returns the access levels that are peers or lower' do
          expect(helper.access_level_roles_user_can_assign(grand_parent, group.access_level_roles)).to be_empty
          expect(helper.access_level_roles_user_can_assign(parent, group.access_level_roles)).to eq({
            'Guest' => ::Gitlab::Access::GUEST,
            'Planner' => ::Gitlab::Access::PLANNER,
            'Reporter' => ::Gitlab::Access::REPORTER,
            'Developer' => ::Gitlab::Access::DEVELOPER
          })
          expect(helper.access_level_roles_user_can_assign(child, group.access_level_roles)).to eq(::Gitlab::Access.options)
          expect(helper.access_level_roles_user_can_assign(grand_child, group.access_level_roles)).to eq(::Gitlab::Access.options_with_owner)
        end
      end

      context 'when a group is linked to another' do
        let_it_be(:other_group) { create(:group) }
        let_it_be(:group_link) { create(:group_group_link, shared_group: group, shared_with_group: other_group, group_access: Gitlab::Access::MAINTAINER) }

        before_all do
          other_group.add_owner(user)
        end

        it { is_expected.to eq(::Gitlab::Access.options) }
      end

      context 'when user is not provided' do
        before do
          allow(helper).to receive(:current_user).and_return(nil)
        end

        it 'returns the empty array' do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe '#show_prevent_inviting_groups_outside_hierarchy_setting?' do
    let_it_be(:group) { create(:group) }

    it 'returns true for a root group' do
      expect(helper.show_prevent_inviting_groups_outside_hierarchy_setting?(group)).to eq(true)
    end

    it 'returns false for a subgroup' do
      subgroup = create(:group, parent: group)

      expect(helper.show_prevent_inviting_groups_outside_hierarchy_setting?(subgroup)).to eq(false)
    end
  end

  describe('#group_confirm_modal_data') do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group, path: "foo") }

    fake_form_id = "fake_form_id"
    where(:prevent_delete_response, :is_button_disabled, :form_value_id, :permanently_remove, :button_text, :has_security_policy_project) do
      true      | "true"      | nil           |  false  | "Delete" | true
      true      | "true"      | fake_form_id  |  true   | nil | false
      false     | "true" | nil | false | "Delete group" | true
      false     | "false" | fake_form_id | true | nil | false
    end

    with_them do
      it "returns expected parameters" do
        allow(group).to receive(:linked_to_subscription?).and_return(prevent_delete_response)

        expected = helper.group_confirm_modal_data(group: group, remove_form_id: form_value_id, button_text: button_text, has_security_policy_project: has_security_policy_project)
        expect(expected).to eq({
          button_text: button_text.nil? ? "Delete group" : button_text,
          confirm_danger_message: remove_group_message(group, permanently_remove),
          remove_form_id: form_value_id,
          phrase: group.full_path,
          button_testid: "remove-group-button",
          disabled: is_button_disabled,
          html_confirmation_message: 'true'
        })
      end
    end
  end

  describe '#group_merge_requests' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:merge_request) { create(:merge_request, :simple, source_project: project, target_project: project) }

    before do
      group.add_owner(user)

      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns group merge requests' do
      expect(helper.group_merge_requests(group)).to contain_exactly(merge_request)
    end
  end
end
