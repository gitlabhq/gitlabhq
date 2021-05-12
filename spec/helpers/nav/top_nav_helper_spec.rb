# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nav::TopNavHelper do
  include ActionView::Helpers::UrlHelper

  describe '#top_nav_view_model' do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:admin) { build_stubbed(:user, :admin) }

    let(:current_user) { nil }
    let(:current_project) { nil }
    let(:current_group) { nil }
    let(:with_current_settings_admin_mode) { false }
    let(:with_header_link_admin_mode) { false }
    let(:with_sherlock_enabled) { false }
    let(:with_projects) { false }
    let(:with_groups) { false }
    let(:with_milestones) { false }
    let(:with_snippets) { false }
    let(:with_activity) { false }

    let(:subject) { helper.top_nav_view_model(project: current_project, group: current_group) }

    let(:active_title) { 'Menu' }

    before do
      allow(helper).to receive(:current_user) { current_user }
      allow(Gitlab::CurrentSettings).to receive(:admin_mode) { with_current_settings_admin_mode }
      allow(helper).to receive(:header_link?).with(:admin_mode) { with_header_link_admin_mode }
      allow(Gitlab::Sherlock).to receive(:enabled?) { with_sherlock_enabled }

      # Defaulting all `dashboard_nav_link?` calls to false ensures the EE-specific behavior
      # is not enabled in this CE spec
      allow(helper).to receive(:dashboard_nav_link?).with(anything) { false }

      allow(helper).to receive(:dashboard_nav_link?).with(:projects) { with_projects }
      allow(helper).to receive(:dashboard_nav_link?).with(:groups) { with_groups }
      allow(helper).to receive(:dashboard_nav_link?).with(:milestones) { with_milestones }
      allow(helper).to receive(:dashboard_nav_link?).with(:snippets) { with_snippets }
      allow(helper).to receive(:dashboard_nav_link?).with(:activity) { with_activity }
    end

    it 'has :activeTitle' do
      expect(subject[:activeTitle]).to eq(active_title)
    end

    context 'when current_user is nil (anonymous)' do
      it 'has expected :primary' do
        expected_projects_item = ::Gitlab::Nav::TopNavMenuItem.build(
          href: '/explore',
          icon: 'project',
          id: 'project',
          title: 'Projects'
        )
        expected_groups_item = ::Gitlab::Nav::TopNavMenuItem.build(
          href: '/explore/groups',
          icon: 'group',
          id: 'groups',
          title: 'Groups'
        )
        expected_snippets_item = ::Gitlab::Nav::TopNavMenuItem.build(
          href: '/explore/snippets',
          icon: 'snippet',
          id: 'snippets',
          title: 'Snippets'
        )
        expect(subject[:primary])
          .to eq([
                   expected_projects_item,
                   expected_groups_item,
                   expected_snippets_item
                 ])
      end
    end

    context 'when current_user is non-admin' do
      let(:current_user) { user }

      it 'has no menu items or views by default' do
        expect(subject).to eq({ activeTitle: active_title,
                                primary: [],
                                secondary: [],
                                views: {} })
      end

      context 'with projects' do
        let(:with_projects) { true }
        let(:projects_view) { subject[:views][:projects] }

        it 'has expected :primary' do
          expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
            css_class: 'qa-projects-dropdown',
            data: {
              track_event: 'click_dropdown',
              track_experiment: 'new_repo',
              track_label: 'projects_dropdown'
            },
            icon: 'project',
            id: 'project',
            title: 'Projects',
            view: 'projects'
          )
          expect(subject[:primary]).to eq([expected_primary])
        end

        context 'projects' do
          it 'has expected :currentUserName' do
            expect(projects_view[:currentUserName]).to eq(current_user.username)
          end

          it 'has expected :namespace' do
            expect(projects_view[:namespace]).to eq('projects')
          end

          it 'has expected :linksPrimary' do
            expected_links_primary = [
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/dashboard/projects',
                id: 'your',
                title: 'Your projects'
              ),
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/dashboard/projects/starred',
                id: 'starred',
                title: 'Starred projects'
              ),
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/explore',
                id: 'explore',
                title: 'Explore projects'
              )
            ]
            expect(projects_view[:linksPrimary]).to eq(expected_links_primary)
          end

          it 'has expected :linksSecondary' do
            expected_links_secondary = [
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/projects/new',
                id: 'create',
                title: 'Create new project'
              )
            ]
            expect(projects_view[:linksSecondary]).to eq(expected_links_secondary)
          end

          context 'with persisted project' do
            let_it_be(:project) { build_stubbed(:project) }

            let(:current_project) { project }
            let(:avatar_url) { 'project_avatar_url' }

            before do
              allow(project).to receive(:persisted?) { true }
              allow(project).to receive(:avatar_url) { avatar_url }
            end

            it 'has project as :container' do
              expected_container = {
                avatarUrl: avatar_url,
                id: project.id,
                name: project.name,
                namespace: project.full_name,
                webUrl: project_path(project)
              }

              expect(projects_view[:currentItem]).to eq(expected_container)
            end
          end
        end
      end

      context 'with groups' do
        let(:with_groups) { true }
        let(:groups_view) { subject[:views][:groups] }

        it 'has expected :primary' do
          expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
            css_class: 'qa-groups-dropdown',
            data: {
              track_event: 'click_dropdown',
              track_label: 'groups_dropdown'
            },
            icon: 'group',
            id: 'groups',
            title: 'Groups',
            view: 'groups'
          )
          expect(subject[:primary]).to eq([expected_primary])
        end

        context 'groups' do
          it 'has expected :currentUserName' do
            expect(groups_view[:currentUserName]).to eq(current_user.username)
          end

          it 'has expected :namespace' do
            expect(groups_view[:namespace]).to eq('groups')
          end

          it 'has expected :linksPrimary' do
            expected_links_primary = [
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/dashboard/groups',
                id: 'your',
                title: 'Your groups'
              ),
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/explore/groups',
                id: 'explore',
                title: 'Explore groups'
              )
            ]
            expect(groups_view[:linksPrimary]).to eq(expected_links_primary)
          end

          it 'has expected :linksSecondary' do
            expected_links_secondary = [
              ::Gitlab::Nav::TopNavMenuItem.build(
                href: '/groups/new#create-group-pane',
                id: 'create',
                title: 'Create group'
              )
            ]
            expect(groups_view[:linksSecondary]).to eq(expected_links_secondary)
          end

          context 'with persisted group' do
            let_it_be(:group) { build_stubbed(:group) }

            let(:current_group) { group }
            let(:avatar_url) { 'group_avatar_url' }

            before do
              allow(group).to receive(:persisted?) { true }
              allow(group).to receive(:avatar_url) { avatar_url }
            end

            it 'has expected :container' do
              expected_container = {
                avatarUrl: avatar_url,
                id: group.id,
                name: group.name,
                namespace: group.full_name,
                webUrl: group_path(group)
              }

              expect(groups_view[:currentItem]).to eq(expected_container)
            end
          end
        end
      end

      context 'with milestones' do
        let(:with_milestones) { true }

        it 'has expected :primary' do
          expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
            data: {
              qa_selector: 'milestones_link'
            },
            href: '/dashboard/milestones',
            icon: 'clock',
            id: 'milestones',
            title: 'Milestones'
          )
          expect(subject[:primary]).to eq([expected_primary])
        end
      end

      context 'with snippets' do
        let(:with_snippets) { true }

        it 'has expected :primary' do
          expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
            data: {
              qa_selector: 'snippets_link'
            },
            href: '/dashboard/snippets',
            icon: 'snippet',
            id: 'snippets',
            title: 'Snippets'
          )
          expect(subject[:primary]).to eq([expected_primary])
        end
      end

      context 'with activity' do
        let(:with_activity) { true }

        it 'has expected :primary' do
          expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
            data: {
              qa_selector: 'activity_link'
            },
            href: '/dashboard/activity',
            icon: 'history',
            id: 'activity',
            title: 'Activity'
          )
          expect(subject[:primary]).to eq([expected_primary])
        end
      end

      context 'when sherlock is enabled' do
        let(:with_sherlock_enabled) { true }

        before do
          # Note: We have to mock the sherlock route because the route is conditional on
          # sherlock being enabled, but it parsed at Rails load time and can't be overridden
          # in a spec.
          allow(helper).to receive(:sherlock_transactions_path) { '/fake_sherlock_path' }
        end

        it 'has sherlock as last :secondary item' do
          expected_sherlock_item = ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'sherlock',
            title: 'Sherlock Transactions',
            icon: 'admin',
            href: '/fake_sherlock_path'
          )
          expect(subject[:secondary].last).to eq(expected_sherlock_item)
        end
      end
    end

    context 'when current_user is admin' do
      let_it_be(:current_user) { admin }

      let(:with_current_settings_admin_mode) { true }

      it 'has admin as first :secondary item' do
        expected_admin_item = ::Gitlab::Nav::TopNavMenuItem.build(
          id: 'admin',
          title: 'Admin',
          icon: 'admin',
          href: '/admin',
          css_class: 'qa-admin-area-link'
        )

        expect(subject[:secondary].first).to eq(expected_admin_item)
      end

      context 'with header link admin_mode true' do
        let(:with_header_link_admin_mode) { true }

        it 'has leave_admin_mode as last :secondary item' do
          expected_leave_admin_mode_item = ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'leave_admin_mode',
            title: 'Leave Admin Mode',
            icon: 'lock-open',
            href: '/admin/session/destroy',
            method: :post
          )
          expect(subject[:secondary].last).to eq(expected_leave_admin_mode_item)
        end
      end

      context 'with header link admin_mode false' do
        let(:with_header_link_admin_mode) { false }

        it 'has enter_admin_mode as last :secondary item' do
          expected_enter_admin_mode_item = ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'enter_admin_mode',
            title: 'Enter Admin Mode',
            icon: 'lock',
            href: '/admin/session/new'
          )
          expect(subject[:secondary].last).to eq(expected_enter_admin_mode_item)
        end
      end
    end
  end
end
