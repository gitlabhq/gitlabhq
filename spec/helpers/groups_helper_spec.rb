# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsHelper do
  include ApplicationHelper

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

  describe '#group_dependency_proxy_url' do
    it 'converts uppercase letters to lowercase' do
      group = build_stubbed(:group, path: 'GroupWithUPPERcaseLetters')

      expect(group_dependency_proxy_url(group)).to end_with("/groupwithuppercaseletters#{DependencyProxy::URL_SUFFIX}")
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
            .to match(%r{<li style="text-indent: 16px;"><a.*>#{deep_nested_group.name}.*</li>.*<a.*>#{very_deep_nested_group.name}</a>}m)
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

  describe '#group_container_registry_nav' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    before do
      stub_container_registry_config(enabled: true)
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(user, :read_container_image, group) { true }
      helper.instance_variable_set(:@group, group)
    end

    subject { helper.group_container_registry_nav? }

    context 'when container registry is enabled' do
      it { is_expected.to be_truthy }

      it 'is disabled for guest' do
        allow(helper).to receive(:can?).with(user, :read_container_image, group) { false }
        expect(subject).to be false
      end
    end

    context 'when container registry is not enabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it { is_expected.to be_falsy }

      it 'is disabled for guests' do
        allow(helper).to receive(:can?).with(user, :read_container_image, group) { false }
        expect(subject).to be false
      end
    end
  end

  describe '#group_sidebar_links' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    before do
      group.add_owner(user)
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
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

      allow(Ability).to receive(:allowed?).and_call_original
      cross_project_features.each do |feature|
        expect(Ability).to receive(:allowed?).with(user, "read_group_#{feature}".to_sym, group) { false }
      end

      expect(helper.group_sidebar_links).not_to include(*cross_project_features)
    end
  end

  describe '#parent_group_options' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group, name: 'group') }
    let_it_be(:group2) { create(:group, name: 'group2') }

    before do
      group.add_owner(current_user)
      group2.add_owner(current_user)
    end

    it 'includes explicitly owned groups except self' do
      expect(parent_group_options(group2)).to eq([{ id: group.id, text: group.human_name }].to_json)
    end

    it 'excludes parent group' do
      subgroup = create(:group, parent: group2)

      expect(parent_group_options(subgroup)).to eq([{ id: group.id, text: group.human_name }].to_json)
    end

    it 'includes subgroups with inherited ownership' do
      subgroup = create(:group, parent: group)

      expect(parent_group_options(group2)).to eq([{ id: group.id, text: group.human_name }, { id: subgroup.id, text: subgroup.human_name }].to_json)
    end

    it 'excludes own subgroups' do
      create(:group, parent: group2)

      expect(parent_group_options(group2)).to eq([{ id: group.id, text: group.human_name }].to_json)
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

  describe '#show_thanks_for_purchase_banner?' do
    subject { helper.show_thanks_for_purchase_banner? }

    it 'returns true with purchased_quantity present in params' do
      allow(controller).to receive(:params) { { purchased_quantity: '1' } }

      is_expected.to be_truthy
    end

    it 'returns false with purchased_quantity not present in params' do
      is_expected.to be_falsey
    end

    it 'returns false with purchased_quantity is empty in params' do
      allow(controller).to receive(:params) { { purchased_quantity: '' } }

      is_expected.to be_falsey
    end
  end

  describe '#show_invite_banner?' do
    let_it_be(:current_user) { create(:user) }
    let_it_be_with_refind(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:users) { [current_user, create(:user)] }

    before do
      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?).with(current_user, :admin_group, group).and_return(can_admin_group)
      allow(helper).to receive(:can?).with(current_user, :admin_group, subgroup).and_return(can_admin_group)
      users.take(group_members_count).each { |user| group.add_guest(user) }
    end

    using RSpec::Parameterized::TableSyntax

    where(:can_admin_group, :group_members_count, :expected_result) do
      true  | 1 | true
      false | 1 | false
      true  | 2 | false
      false | 2 | false
    end

    with_them do
      context 'for a parent group' do
        subject { helper.show_invite_banner?(group) }

        context 'when the group was just created' do
          before do
            flash[:notice] = "Group #{group.name} was successfully created"
          end

          it { is_expected.to be_falsey }
        end

        context 'when no flash message' do
          it 'returns the expected result' do
            expect(subject).to eq(expected_result)
          end
        end
      end

      context 'for a subgroup' do
        subject { helper.show_invite_banner?(subgroup) }

        context 'when the subgroup was just created' do
          before do
            flash[:notice] = "Group #{subgroup.name} was successfully created"
          end

          it { is_expected.to be_falsey }
        end

        context 'when no flash message' do
          it 'returns the expected result' do
            expect(subject).to eq(expected_result)
          end
        end
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

  describe '#cached_issuables_count' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group, name: 'group') }

    context 'with issues type' do
      let(:type) { :issues }
      let(:count_service) { Groups::OpenIssuesCountService }

      it_behaves_like 'cached issuables count'
    end

    context 'with merge requests type' do
      let(:type) { :merge_requests }
      let(:count_service) { Groups::MergeRequestsCountService }

      it_behaves_like 'cached issuables count'
    end
  end
end
