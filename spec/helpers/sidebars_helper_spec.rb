# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidebarsHelper, feature_category: :navigation do
  include Devise::Test::ControllerHelpers

  let_it_be(:current_organization) { build_stubbed(:organization, name: "Current Organization") }

  before do
    Current.organization = current_organization
  end

  describe '#sidebar_tracking_attributes_by_object' do
    subject(:tracking_attrs) { helper.sidebar_tracking_attributes_by_object(object) }

    before do
      stub_application_setting(snowplow_enabled: true)
    end

    context 'when object is a project' do
      let(:object) { build(:project) }

      it 'returns tracking attrs for project' do
        attrs = {
          track_label: 'projects_side_navigation',
          track_property: 'projects_side_navigation',
          track_action: 'render'
        }

        expect(tracking_attrs[:data]).to eq(attrs)
      end
    end

    context 'when object is a group' do
      let(:object) { build(:group) }

      it 'returns tracking attrs for group' do
        attrs = {
          track_label: 'groups_side_navigation',
          track_property: 'groups_side_navigation',
          track_action: 'render'
        }

        expect(tracking_attrs[:data]).to eq(attrs)
      end
    end

    context 'when object is a user' do
      let(:object) { build(:user) }

      it 'returns tracking attrs for user' do
        attrs = {
          track_label: 'user_side_navigation',
          track_property: 'user_side_navigation',
          track_action: 'render'
        }

        expect(tracking_attrs[:data]).to eq(attrs)
      end
    end

    context 'when object is something else' do
      let(:object) { build(:ci_pipeline) }

      it { is_expected.to eq({}) }
    end
  end

  describe '#super_sidebar_context' do
    include_context 'custom session'

    let_it_be(:user) { build(:user) }
    let_it_be(:group) { build(:group) }
    let_it_be(:group_with_id) { build_stubbed(:group) }
    let_it_be(:panel) { {} }
    let_it_be(:panel_type) { 'project' }
    let(:project) { nil }
    let(:current_user_mode) { Gitlab::Auth::CurrentUserMode.new(user) }
    let(:context_with_group_id) do
      helper.super_sidebar_context(user, group: group_with_id, project: project, panel: panel, panel_type: panel_type)
    end

    let(:global_shortcut_links) do
      [
        {
          title: _('Milestones'),
          href: dashboard_milestones_path,
          css_class: 'dashboard-shortcuts-milestones'
        },
        {
          title: _('Snippets'),
          href: dashboard_snippets_path,
          css_class: 'dashboard-shortcuts-snippets'
        },
        {
          title: _('Activity'),
          href: activity_dashboard_path,
          css_class: 'dashboard-shortcuts-activity'
        },
        {
          title: _('Groups'),
          href: dashboard_groups_path,
          css_class: 'dashboard-shortcuts-groups'
        },
        {
          title: _('Projects'),
          href: dashboard_projects_path,
          css_class: 'dashboard-shortcuts-projects'
        }
      ]
    end

    subject do
      helper.super_sidebar_context(user, group: group, project: project, panel: panel, panel_type: panel_type)
    end

    before do
      allow(Time).to receive(:now).and_return(Time.utc(2021, 1, 1))
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:session).and_return(session)
      allow(helper).to receive(:header_search_context).and_return({ some: "search data" })
      allow(helper).to receive(:current_user_mode).and_return(current_user_mode)
      allow(panel).to receive(:super_sidebar_menu_items).and_return(nil)
      allow(panel).to receive(:super_sidebar_context_header).and_return(nil)

      if user
        allow(user).to receive(:assigned_open_issues_count).and_return(1)
        allow(user).to receive(:assigned_open_merge_requests_count).and_return(4)
        allow(user).to receive(:review_requested_open_merge_requests_count).and_return(0)
        allow(user).to receive(:todos_pending_count).and_return(3)
        allow(user).to receive(:pinned_nav_items).and_return({ panel_type => %w[foo bar], 'another_panel' => %w[baz] })
      end
    end

    # Tests for logged-out sidebar context
    it_behaves_like 'logged-out super-sidebar context'

    # Tests for logged-in sidebar context below
    it_behaves_like 'shared super sidebar context'
    it { is_expected.to include({ is_logged_in: true }) }

    it 'returns terms if defined' do
      stub_application_setting(terms: "My custom Terms of Use")

      is_expected.to include({ terms: "/-/users/terms" })
    end

    it 'does not return terms if not set' do
      is_expected.to include({ terms: nil })
    end

    it 'returns sidebar values from user', :use_clean_rails_memory_store_caching do
      expect(subject).to include({
        is_logged_in: true,
        is_admin: false,
        name: user.name,
        username: user.username,
        admin_url: admin_root_url,
        admin_mode: {
          admin_mode_feature_enabled: true,
          admin_mode_active: false,
          enter_admin_mode_url: new_admin_session_path,
          leave_admin_mode_url: destroy_admin_session_path,
          user_is_admin: false
        },
        avatar_url: user.avatar_url,
        has_link_to_profile: helper.current_user_menu?(:profile),
        link_to_profile: user_path(user),
        status: {
          can_update: helper.can?(user, :update_user_status, user),
          busy: user.status&.busy?,
          customized: user.status&.customized?,
          availability: user.status&.availability.to_s,
          emoji: user.status&.emoji,
          message_html: user.status&.message_html&.html_safe,
          message: user.status&.message&.html_safe,
          clear_after: nil
        },
        settings: {
          has_settings: helper.current_user_menu?(:settings),
          profile_path: user_settings_profile_path,
          profile_preferences_path: profile_preferences_path
        },
        user_counts: {
          assigned_issues: 1,
          assigned_merge_requests: 4,
          review_requested_merge_requests: 0,
          todos: 3,
          last_update: 1609459200000
        },
        can_sign_out: helper.current_user_menu?(:sign_out),
        sign_out_link: destroy_user_session_path,
        issues_dashboard_path: issues_dashboard_path(assignee_username: user.username),
        todos_dashboard_path: dashboard_todos_path,
        projects_path: dashboard_projects_path,
        groups_path: dashboard_groups_path,
        gitlab_com_but_not_canary: Gitlab.com_but_not_canary?,
        gitlab_com_and_canary: Gitlab.com_and_canary?,
        canary_toggle_com_url: Gitlab::Saas.canary_toggle_com_url,
        pinned_items: %w[foo bar],
        update_pins_url: pins_path,
        shortcut_links: global_shortcut_links,
        track_visits_path: track_namespace_visits_path,
        work_items: nil
      })
    end

    it 'returns sidebar values for work item context with group id', :use_clean_rails_memory_store_caching do
      expect(context_with_group_id).to include({
        work_items: {
          full_path: group_with_id.full_path,
          has_issuable_health_status_feature: "false",
          issues_list_path: issues_group_path(group_with_id),
          labels_manage_path: group_labels_path(group_with_id),
          can_admin_label: "true"
        }
      })
    end

    context 'when user is admin' do
      before do
        allow(user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it { is_expected.to include({ is_admin: true }) }
    end

    describe "what's new information" do
      context 'when display_whats_new? is true' do
        before do
          allow(helper).to receive(:display_whats_new?).and_return(true)
        end

        it do
          is_expected.to include({
            whats_new_most_recent_release_items_count: helper.whats_new_most_recent_release_items_count,
            whats_new_version_digest: helper.whats_new_version_digest
          })
        end
      end

      context 'when display_whats_new? is false' do
        before do
          allow(helper).to receive(:display_whats_new?).and_return(false)
        end

        it do
          is_expected.not_to have_key(:whats_new_most_recent_release_items_count)
          is_expected.not_to have_key(:whats_new_version_digest)
        end
      end
    end

    describe 'instance version information' do
      context 'when show_version_check? is true' do
        before do
          allow(helper).to receive(:show_version_check?).and_return(true)
        end

        it do
          is_expected.to include({
            gitlab_version: Gitlab.version_info,
            gitlab_version_check: helper.gitlab_version_check
          })
        end
      end

      context 'when show_version_check? is false' do
        before do
          allow(helper).to receive(:show_version_check?).and_return(false)
        end

        it do
          is_expected.not_to have_key(:gitlab_version)
          is_expected.not_to have_key(:gitlab_version_check)
        end
      end
    end

    describe "shortcut links" do
      describe "as the anonymous user" do
        let_it_be(:user) { nil }
        let(:global_shortcut_links) do
          [
            {
              title: _('Snippets'),
              href: explore_snippets_path,
              css_class: 'dashboard-shortcuts-snippets'
            },
            {
              title: _('Groups'),
              href: explore_groups_path,
              css_class: 'dashboard-shortcuts-groups'
            },
            {
              title: _('Projects'),
              href: starred_explore_projects_path,
              css_class: 'dashboard-shortcuts-projects'
            }
          ]
        end

        it 'returns global shortcut links' do
          expect(subject[:shortcut_links]).to eq(global_shortcut_links)
        end

        context 'in a project' do
          let_it_be(:project) { build_stubbed(:project) }

          it 'returns project-specific shortcut links' do
            expect(subject[:shortcut_links]).to eq(global_shortcut_links)
          end
        end
      end

      describe "as logged-in user" do
        it 'returns global shortcut links' do
          expect(subject[:shortcut_links]).to eq(global_shortcut_links)
        end

        context 'in a project' do
          let_it_be(:project) { build_stubbed(:project) }

          it 'returns project-specific shortcut links' do
            expect(subject[:shortcut_links]).to eq([
              *global_shortcut_links,
              {
                title: _('Create a new issue'),
                href: new_project_issue_path(project),
                css_class: 'shortcuts-new-issue'
              }
            ])
          end
        end
      end
    end

    it 'returns "Merge requests" menu', :use_clean_rails_memory_store_caching do
      expect(subject[:merge_request_menu]).to eq([
        {
          name: _('Merge requests'),
          items: [
            {
              text: _('Assigned'),
              href: merge_requests_dashboard_path(assignee_username: user.username),
              count: 4,
              userCount: 'assigned_merge_requests',
              extraAttrs: {
                'data-track-action': 'click_link',
                'data-track-label': 'merge_requests_assigned',
                'data-track-property': 'nav_core_menu',
                class: 'dashboard-shortcuts-merge_requests'
              }
            },
            {
              text: _('Review requests'),
              href: merge_requests_dashboard_path(reviewer_username: user.username),
              count: 0,
              userCount: 'review_requested_merge_requests',
              extraAttrs: {
                'data-track-action': 'click_link',
                'data-track-label': 'merge_requests_to_review',
                'data-track-property': 'nav_core_menu',
                class: 'dashboard-shortcuts-review_requests'
              }
            }
          ]
        }
      ])
    end

    context 'when merge_request_dashboard feature flag is enabled' do
      before do
        stub_feature_flags(merge_request_dashboard: true)
      end

      it 'returns nil for merge_request_menu' do
        expect(subject[:merge_request_menu]).to be_nil
      end
    end

    it 'returns "Create new" menu groups without headers', :use_clean_rails_memory_store_caching do
      extra_attrs = ->(id) {
        {
          "data-track-label": id,
          "data-track-action": "click_link",
          "data-track-property": "nav_create_menu",
          "data-testid": 'create_menu_item',
          "data-qa-create-menu-item": id
        }
      }

      expect(subject[:create_new_menu_groups]).to eq([
        {
          name: "",
          items: [
            { href: "/projects/new", text: "New project/repository",
              component: nil,
              extraAttrs: extra_attrs.call("general_new_project") },
            { href: "/groups/new", text: "New group",
              component: nil,
              extraAttrs: extra_attrs.call("general_new_group") },
            { href: "/-/organizations/new", text: s_('Organization|New organization'),
              component: nil,
              extraAttrs: extra_attrs.call("general_new_organization") },
            { href: "/-/snippets/new", text: "New snippet",
              component: nil,
              extraAttrs: extra_attrs.call("general_new_snippet") }
          ]
        }
      ])
    end

    it 'returns "Create new" menu groups with headers', :use_clean_rails_memory_store_caching do
      extra_attrs = ->(id) {
        {
          "data-track-label": id,
          "data-track-action": "click_link",
          "data-track-property": "nav_create_menu",
          "data-testid": 'create_menu_item',
          "data-qa-create-menu-item": id
        }
      }

      allow(group).to receive(:persisted?).and_return(true)
      allow(helper).to receive(:can?).and_return(true)

      expect(subject[:create_new_menu_groups]).to contain_exactly(
        a_hash_including(
          name: "In this group",
          items: array_including(
            { href: "/projects/new", text: "New project/repository",
              component: nil,
              extraAttrs: extra_attrs.call("new_project") },
            { href: "/groups/new#create-group-pane", text: "New subgroup",
              component: nil,
              extraAttrs: extra_attrs.call("new_subgroup") },
            { href: nil, text: "Invite members",
              component: 'invite_members',
              extraAttrs: extra_attrs.call("invite") }
          )
        ),
        a_hash_including(
          name: "In GitLab",
          items: array_including(
            { href: "/projects/new", text: "New project/repository",
              component: nil,
              extraAttrs: extra_attrs.call("general_new_project") },
            { href: "/groups/new", text: "New group",
              component: nil,
              extraAttrs: extra_attrs.call("general_new_group") },
            { href: "/-/snippets/new", text: "New snippet",
              component: nil,
              extraAttrs: extra_attrs.call("general_new_snippet") }
          )
        )
      )
    end

    describe 'current context' do
      context 'when current context is a project' do
        let_it_be(:project) { build(:project) }

        subject do
          helper.super_sidebar_context(user, group: nil, project: project, panel: panel, panel_type: panel_type)
        end

        before do
          allow(project).to receive(:persisted?).and_return(true)
        end

        it 'returns project context' do
          expect(subject[:current_context]).to eq({
            namespace: 'projects',
            item: {
              id: project.id,
              avatarUrl: project.avatar_url,
              name: project.name,
              namespace: project.full_name,
              fullPath: project.full_path,
              webUrl: project_path(project)
            }
          })
        end
      end

      context 'when current context is a group' do
        subject do
          helper.super_sidebar_context(user, group: group, project: nil, panel: panel, panel_type: panel_type)
        end

        before do
          allow(group).to receive(:persisted?).and_return(true)
        end

        it 'returns group context' do
          expect(subject[:current_context]).to eq({
            namespace: 'groups',
            item: {
              id: group.id,
              avatarUrl: group.avatar_url,
              name: group.name,
              namespace: group.full_name,
              fullPath: group.full_path,
              webUrl: group_path(group)
            }
          })
        end
      end

      context 'when current context is not tracked' do
        subject do
          helper.super_sidebar_context(user, group: nil, project: nil, panel: panel, panel_type: panel_type)
        end

        it 'returns no context' do
          expect(subject[:current_context]).to eq({})
        end
      end
    end

    describe 'context switcher persistent links' do
      let_it_be(:public_link) do
        { title: s_('Navigation|Explore'), link: '/explore', icon: 'compass' }
      end

      let_it_be(:public_links_for_user) do
        [
          { title: s_('Navigation|Your work'), link: '/', icon: 'work' },
          public_link,
          { title: s_('Navigation|Profile'), link: '/-/user_settings/profile', icon: 'profile' },
          { title: s_('Navigation|Preferences'), link: '/-/profile/preferences', icon: 'preferences' }
        ]
      end

      let_it_be(:admin_area_link) do
        { title: s_('Navigation|Admin area'), link: '/admin', icon: 'admin' }
      end

      subject do
        helper.super_sidebar_context(user, group: nil, project: nil, panel: panel, panel_type: panel_type)
      end

      context 'when user is not logged in' do
        let(:user) { nil }

        it 'returns only the public links for an anonymous user' do
          expect(subject[:context_switcher_links]).to eq([public_link])
        end
      end

      context 'when user is not an admin' do
        it 'returns only the public links for a user' do
          expect(subject[:context_switcher_links]).to eq(public_links_for_user)
        end
      end

      context 'when user is an admin' do
        before do
          allow(user).to receive(:admin?).and_return(true)
        end

        context 'when application setting :admin_mode is enabled' do
          before do
            stub_application_setting(admin_mode: true)
          end

          context 'when admin mode is on' do
            before do
              current_user_mode.request_admin_mode!
              current_user_mode.enable_admin_mode!(password: user.password)
            end

            it 'returns public links, admin area and leave admin mode links' do
              expect(subject[:context_switcher_links]).to eq([
                *public_links_for_user,
                admin_area_link
              ])
            end
          end

          context 'when admin mode is off' do
            it 'returns public links and enter admin mode link' do
              expect(subject[:context_switcher_links]).to eq([
                *public_links_for_user
              ])
            end
          end
        end

        context 'when application setting :admin_mode is disabled' do
          before do
            stub_application_setting(admin_mode: false)
          end

          it 'returns public links and admin area link' do
            expect(subject[:context_switcher_links]).to eq([
              *public_links_for_user,
              admin_area_link
            ])
          end
        end
      end
    end

    describe 'impersonation data' do
      it 'sets is_impersonating to `false` when not impersonating' do
        expect(subject[:is_impersonating]).to be(false)
      end

      it 'passes the stop_impersonation_path property' do
        expect(subject[:stop_impersonation_path]).to eq(admin_impersonation_path)
      end

      describe 'when impersonating' do
        before do
          session[:impersonator_id] = 5
        end

        it 'sets is_impersonating to `true`' do
          expect(subject[:is_impersonating]).to be(true)
        end
      end
    end
  end

  describe '#super_sidebar_nav_panel' do
    let(:group) { build(:group) }
    let(:project) { build(:project) }
    let(:organization) { build(:organization) }

    before do
      allow(helper).to receive(:project_sidebar_context_data).and_return(
        { current_user: nil, container: project, can_view_pipeline_editor: false, learn_gitlab_enabled: false })
      allow(helper).to receive(:group_sidebar_context_data).and_return(
        { current_user: nil, container: group, show_discover_group_security: false })

      allow(group).to receive(:to_global_id).and_return(5)
    end

    shared_examples 'nav panels available to logged-out users' do
      it 'returns Project Panel for project nav' do
        expect(helper.super_sidebar_nav_panel(nav: 'project',
          user: user)).to be_a(Sidebars::Projects::SuperSidebarPanel)
      end

      it 'returns Group Panel for group nav' do
        expect(helper.super_sidebar_nav_panel(nav: 'group', user: user)).to be_a(Sidebars::Groups::SuperSidebarPanel)
      end

      it 'returns User profile Panel for user profile nav' do
        viewed_user = build(:user)
        expect(helper.super_sidebar_nav_panel(nav: 'user_profile', user: user,
          viewed_user: viewed_user)).to be_a(Sidebars::UserProfile::Panel)
      end

      it 'returns Explore Panel for explore nav' do
        expect(helper.super_sidebar_nav_panel(nav: 'explore', user: user)).to be_a(Sidebars::Explore::Panel)
      end

      it 'returns Organization Panel for organization nav' do
        expect(
          helper.super_sidebar_nav_panel(nav: 'organization', organization: organization, user: user)
        ).to be_a(Sidebars::Organizations::SuperSidebarPanel)
      end

      it 'returns Search Panel for search nav' do
        expect(helper.super_sidebar_nav_panel(nav: 'search', user: user)).to be_a(Sidebars::Search::Panel)
      end
    end

    describe 'when logged-in' do
      let(:user) { build(:user) }

      before do
        Rails.cache.write(['users', user.id, 'assigned_open_issues_count'], 1)
        Rails.cache.write(['users', user.id, 'assigned_open_merge_requests_count'], 4)
        Rails.cache.write(['users', user.id, 'review_requested_open_merge_requests_count'], 0)
        Rails.cache.write(['users', user.id, 'todos_pending_count'], 3)
      end

      it 'returns User Settings Panel for profile nav' do
        expect(helper.super_sidebar_nav_panel(nav: 'profile', user: user)).to be_a(Sidebars::UserSettings::Panel)
      end

      describe 'admin user' do
        let(:user) { build(:admin) }

        it 'returns Admin Panel for admin nav', :enable_admin_mode do
          expect(helper.super_sidebar_nav_panel(nav: 'admin', user: user)).to be_a(Sidebars::Admin::Panel)
        end
      end

      it 'returns Your Work Panel for admin nav' do
        expect(helper.super_sidebar_nav_panel(nav: 'admin', user: user)).to be_a(Sidebars::YourWork::Panel)
      end

      it 'returns "Your Work" Panel for your_work nav', :use_clean_rails_memory_store_caching do
        expect(helper.super_sidebar_nav_panel(nav: 'your_work', user: user)).to be_a(Sidebars::YourWork::Panel)
      end

      it 'returns "Your Work" Panel as a fallback', :use_clean_rails_memory_store_caching do
        expect(helper.super_sidebar_nav_panel(user: user)).to be_a(Sidebars::YourWork::Panel)
      end

      it_behaves_like 'nav panels available to logged-out users'
    end

    describe 'when logged-out' do
      let(:user) { nil }

      it_behaves_like 'nav panels available to logged-out users'

      it 'returns "Explore" Panel as a fallback' do
        expect(helper.super_sidebar_nav_panel(user: user)).to be_a(Sidebars::Explore::Panel)
      end
    end
  end

  describe '#command_palette_data' do
    it 'returns data for project files search' do
      project = create(:project, :repository) # rubocop:disable RSpec/FactoryBot/AvoidCreate

      expect(helper.command_palette_data(project: project)).to eq(
        project_files_url: project_files_path(
          project, project.default_branch, format: :json),
        project_blob_url: project_blob_path(
          project, project.default_branch)
      )

      current_ref = 'test'

      expect(helper.command_palette_data(project: project, current_ref: current_ref)).to eq(
        project_files_url: project_files_path(
          project, current_ref, format: :json),
        project_blob_url: project_blob_path(
          project, current_ref)
      )
    end

    it 'returns empty object when project is nil' do
      expect(helper.command_palette_data(project: nil)).to eq({})
    end

    it 'returns empty object when project does not have repo' do
      project = build(:project)
      expect(helper.command_palette_data(project: project)).to eq({})
    end

    it 'returns empty object when project has repo but it is empty' do
      project = build(:project, :empty_repo)
      expect(helper.command_palette_data(project: project)).to eq({})
    end
  end
end
