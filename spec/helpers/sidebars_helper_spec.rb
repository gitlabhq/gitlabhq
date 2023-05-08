# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidebarsHelper, feature_category: :navigation do
  include Devise::Test::ControllerHelpers

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
    let_it_be(:user) { build(:user) }
    let_it_be(:group) { build(:group) }
    let_it_be(:panel) { {} }
    let_it_be(:panel_type) { 'project' }
    let(:project) { nil }

    subject do
      helper.super_sidebar_context(user, group: group, project: project, panel: panel, panel_type: panel_type)
    end

    before do
      allow(Time).to receive(:now).and_return(Time.utc(2021, 1, 1))
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:header_search_context).and_return({ some: "search data" })
      allow(panel).to receive(:super_sidebar_menu_items).and_return(nil)
      allow(panel).to receive(:super_sidebar_context_header).and_return(nil)
      allow(user).to receive(:assigned_open_issues_count).and_return(1)
      allow(user).to receive(:assigned_open_merge_requests_count).and_return(4)
      allow(user).to receive(:review_requested_open_merge_requests_count).and_return(0)
      allow(user).to receive(:todos_pending_count).and_return(3)
      allow(user).to receive(:pinned_nav_items).and_return({ panel_type => %w[foo bar], 'another_panel' => %w[baz] })
    end

    it 'returns sidebar values from user', :use_clean_rails_memory_store_caching do
      expect(subject).to include({
        current_context_header: nil,
        current_menu_items: nil,
        name: user.name,
        username: user.username,
        avatar_url: user.avatar_url,
        has_link_to_profile: helper.current_user_menu?(:profile),
        link_to_profile: user_url(user),
        status: {
          can_update: helper.can?(user, :update_user_status, user),
          busy: user.status&.busy?,
          customized: user.status&.customized?,
          availability: user.status&.availability.to_s,
          emoji: user.status&.emoji,
          message: user.status&.message_html&.html_safe,
          clear_after: nil
        },
        settings: {
          has_settings: helper.current_user_menu?(:settings),
          profile_path: profile_path,
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
        support_path: helper.support_url,
        display_whats_new: helper.display_whats_new?,
        whats_new_most_recent_release_items_count: helper.whats_new_most_recent_release_items_count,
        whats_new_version_digest: helper.whats_new_version_digest,
        show_version_check: helper.show_version_check?,
        gitlab_version: Gitlab.version_info,
        gitlab_version_check: helper.gitlab_version_check,
        gitlab_com_but_not_canary: Gitlab.com_but_not_canary?,
        gitlab_com_and_canary: Gitlab.com_and_canary?,
        canary_toggle_com_url: Gitlab::Saas.canary_toggle_com_url,
        search: {
          search_path: search_path,
          issues_path: issues_dashboard_path,
          mr_path: merge_requests_dashboard_path,
          autocomplete_path: search_autocomplete_path,
          search_context: helper.header_search_context
        },
        pinned_items: %w[foo bar],
        panel_type: panel_type,
        update_pins_url: pins_url,
        shortcut_links: [
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
          }
        ]
      })
    end

    describe "shortcut links" do
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
          }
        ]
      end

      it 'returns global shortcut links' do
        expect(subject[:shortcut_links]).to eq(global_shortcut_links)
      end

      context 'in a project' do
        # rubocop: disable RSpec/FactoryBot/AvoidCreate
        let_it_be(:project) { create(:project) }
        # rubocop: enable RSpec/FactoryBot/AvoidCreate

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

    it 'returns "Create new" menu groups without headers', :use_clean_rails_memory_store_caching do
      extra_attrs = ->(id) {
        {
          "data-track-label": id,
          "data-track-action": "click_link",
          "data-track-property": "nav_create_menu",
          "data-qa-selector": 'create_menu_item',
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
          "data-qa-selector": 'create_menu_item',
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
        [
          { title: s_('Navigation|Your work'), link: '/', icon: 'work' },
          { title: s_('Navigation|Explore'), link: '/explore', icon: 'compass' }
        ]
      end

      subject do
        helper.super_sidebar_context(user, group: nil, project: nil, panel: panel, panel_type: panel_type)
      end

      context 'when user is not an admin' do
        it 'returns only the public links' do
          expect(subject[:context_switcher_links]).to eq(public_link)
        end
      end

      context 'when user is an admin' do
        before do
          allow(user).to receive(:can_admin_all_resources?).and_return(true)
        end

        it 'returns public links and admin area link' do
          expect(subject[:context_switcher_links]).to eq([
            *public_link,
            { title: s_('Navigation|Admin Area'), link: '/admin', icon: 'admin' }
          ])
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
        it 'sets is_impersonating to `true`' do
          expect(helper).to receive(:session).and_return({ impersonator_id: 1 })
          expect(subject[:is_impersonating]).to be(true)
        end
      end
    end
  end

  describe '#super_sidebar_nav_panel' do
    let(:user) { build(:user) }
    let(:group) { build(:group) }
    let(:project) { build(:project) }

    before do
      allow(helper).to receive(:project_sidebar_context_data).and_return(
        { current_user: nil, container: project, can_view_pipeline_editor: false, learn_gitlab_enabled: false })
      allow(helper).to receive(:group_sidebar_context_data).and_return(
        { current_user: nil, container: group, show_discover_group_security: false })

      allow(group).to receive(:to_global_id).and_return(5)
      Rails.cache.write(['users', user.id, 'assigned_open_issues_count'], 1)
      Rails.cache.write(['users', user.id, 'assigned_open_merge_requests_count'], 4)
      Rails.cache.write(['users', user.id, 'review_requested_open_merge_requests_count'], 0)
      Rails.cache.write(['users', user.id, 'todos_pending_count'], 3)
    end

    it 'returns Project Panel for project nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'project')).to be_a(Sidebars::Projects::SuperSidebarPanel)
    end

    it 'returns Group Panel for group nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'group')).to be_a(Sidebars::Groups::SuperSidebarPanel)
    end

    it 'returns User Settings Panel for profile nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'profile')).to be_a(Sidebars::UserSettings::Panel)
    end

    it 'returns User profile Panel for user profile nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'user_profile')).to be_a(Sidebars::UserProfile::Panel)
    end

    it 'returns Admin Panel for admin nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'admin')).to be_a(Sidebars::Admin::Panel)
    end

    it 'returns "Your Work" Panel for your_work nav', :use_clean_rails_memory_store_caching do
      expect(helper.super_sidebar_nav_panel(nav: 'your_work', user: user)).to be_a(Sidebars::YourWork::Panel)
    end

    it 'returns Search Panel for search nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'search', user: user)).to be_a(Sidebars::Search::Panel)
    end

    it 'returns "Your Work" Panel as a fallback', :use_clean_rails_memory_store_caching do
      expect(helper.super_sidebar_nav_panel(user: user)).to be_a(Sidebars::YourWork::Panel)
    end
  end
end
