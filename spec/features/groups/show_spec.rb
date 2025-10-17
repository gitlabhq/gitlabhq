# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group show page', :with_current_organization, feature_category: :groups_and_projects do
  include Features::InviteMembersModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:path) { group_path(group) }

  context 'when signed in' do
    context 'with non-admin group concerns' do
      before do
        group.add_developer(user)
        sign_in(user)
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"

      context 'when group does not exist' do
        let(:path) { group_path('not-exist') }

        it { expect(status_code).to eq(404) }
      end
    end

    context 'when user is an owner' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it 'shows the invite banner and persists dismissal', :js do
        visit path

        expect(page).to have_content('Collaborate with your team')

        within_testid('invite-members-banner') do
          click_button('Invite your colleagues')
        end

        page.within(invite_modal_selector) do
          expect(page).to have_content("You're inviting members to the #{group.name} group")

          click_button('Cancel')
        end

        within_testid('invite-members-banner') do
          find_by_testid('close-icon').click
        end

        expect(page).not_to have_content('Collaborate with your team')

        visit path

        expect(page).not_to have_content('Collaborate with your team')
      end

      context 'when group has a project with emoji in description', :js do
        let!(:project) { create(:project, description: ':smile:', namespace: group) }

        it 'shows the project info', :aggregate_failures do
          visit path

          expect(page).to have_content(project.title)
          expect(page).to have_emoji('smile')
        end
      end

      context 'when group has projects' do
        it 'allows users to sorts projects by most stars', :js do
          project1 = create(:project, namespace: group, star_count: 2)
          project2 = create(:project, namespace: group, star_count: 3)
          project3 = create(:project, namespace: group, star_count: 0)

          visit group_path(group, sort: :stars_desc)

          expect(find('li[data-testid^="projects-list-item"]:nth-child(1)')).to have_content(project2.title)
          expect(find('li[data-testid^="projects-list-item"]:nth-child(2)')).to have_content(project1.title)
          expect(find('li[data-testid^="projects-list-item"]:nth-child(3)')).to have_content(project3.title)
          expect(page).to have_selector('button[data-testid="base-dropdown-toggle"]', text: 'Stars')
        end
      end
    end

    context 'with subgroups and projects empty state', :js do
      context 'when user has permissions to create new subgroups or projects' do
        before do
          group.add_owner(user)
          sign_in(user)
        end

        subject(:page_content) do
          visit path
          page
        end

        it 'shows `Create subgroup` link' do
          link = new_group_path(parent_id: group.id, anchor: 'create-group-pane')

          expect(page_content).to have_link(_('Create subgroup'), href: link)
        end

        context 'when current Organization does not have scoped paths' do
          before do
            allow(current_organization).to receive(:scoped_paths?).and_return(false)
          end

          it 'shows `Create project` link' do
            expect(page_content)
              .to have_link(_('Create project'), href: new_project_path(namespace_id: group.id))
          end
        end

        context 'when current Organization has scoped paths' do
          before do
            allow(current_organization).to receive(:scoped_paths?).and_return(true)
          end

          it 'shows `Create project` link' do
            expected_path = new_organization_project_path(
              namespace_id: group.id,
              organization_path: current_organization.path
            )
            expect(page_content)
              .to have_link(_('Create project'), href: expected_path)
          end
        end
      end
    end

    context 'when user does not have permissions to create new subgroups or projects', :js do
      before do
        group.add_reporter(user)
        sign_in(user)
        visit path
      end

      it 'does not show `Create subgroup` link' do
        expect(page).not_to have_link _('Create subgroup')
      end

      it 'does not show `Create project` link' do
        expect(page).not_to have_link _('Create project')
      end

      it 'shows empty state' do
        content = s_('GroupsEmptyState|You do not have necessary permissions to create a subgroup ' \
                     'or project in this group. Please contact an owner of this group to create a ' \
                     'new subgroup or project.')

        expect(page).to have_content(s_('GroupsEmptyState|There are no subgroups or projects in this group'))
        expect(page).to have_content(content)
      end
    end

    describe 'tab frontend routing' do
      context 'when route is not prefixed with group' do
        before do
          group.add_developer(user)
          sign_in(user)
          visit group_path(group)
        end

        it 'still allows for tab navigation and reloading', :js do
          click_link _('Shared projects')
          wait_for_requests
          page.refresh

          expect(page).to have_link('Shared projects')
        end
      end

      context 'when route is prefixed with group' do
        before do
          group.add_developer(user)
          sign_in(user)
          visit group_canonical_path(group)
        end

        it 'still allows for tab navigation and reloading', :js do
          click_link _('Shared projects')
          wait_for_requests
          page.refresh

          expect(page).to have_link('Shared projects')
        end
      end
    end
  end

  context 'when signed out' do
    describe 'RSS' do
      before do
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed without a feed token"
    end
  end

  context 'with subgroup support' do
    let_it_be(:restricted_group) do
      create(:group, subgroup_creation_level: ::Gitlab::Access::OWNER_SUBGROUP_ACCESS)
    end

    context 'for owners' do
      before do
        restricted_group.add_owner(user)
        sign_in(user)
      end

      context 'when subgroups are supported' do
        it 'allows creating subgroups' do
          visit group_path(restricted_group)

          expect(page).to have_link(_('Create subgroup'))
        end
      end
    end

    context 'for maintainers' do
      before do
        sign_in(user)
      end

      context 'when subgroups are supported' do
        context 'when subgroup_creation_level is set to maintainers' do
          let(:relaxed_group) do
            create(:group, subgroup_creation_level: ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
          end

          before do
            relaxed_group.add_maintainer(user)
          end

          it 'allows creating subgroups' do
            visit group_path(relaxed_group)

            expect(page).to have_link(_('Create subgroup'))
          end
        end

        context 'when subgroup_creation_level is set to owners' do
          before do
            restricted_group.add_maintainer(user)
          end

          it 'does not allow creating subgroups' do
            visit group_path(restricted_group)

            expect(page).not_to have_link(_('Create subgroup'))
          end
        end
      end
    end
  end

  context 'for notification button', :js do
    before do
      group.add_maintainer(user)
      sign_in(user)
    end

    it 'is enabled by default' do
      visit path

      expect(page).to have_selector('[data-testid="notification-dropdown"] button:not(.disabled)')
    end

    it 'is disabled if emails are disabled' do
      group.update!(emails_enabled: false)

      visit path

      expect(page).to have_selector('[data-testid="notification-dropdown"] .disabled')
    end
  end

  context 'for page og:description' do
    before do
      group.update!(description: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)')
      group.add_maintainer(user)
      sign_in(user)
      visit path
    end

    it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'
  end

  def click_group_caret(group)
    within_testid("groups-list-item-#{group.id}") do
      find_by_testid('nested-groups-project-list-item-toggle-button').click
    end
    wait_for_requests
  end

  context 'for structured schema markup' do
    let_it_be(:group) { create(:group, :public, :with_avatar, description: 'foo') }
    let_it_be(:subgroup) { create(:group, :public, :with_avatar, parent: group, description: 'bar') }
    let_it_be_with_reload(:project) { create(:project, :public, :with_avatar, namespace: group, description: 'foo') }
    let_it_be(:subproject) { create(:project, :public, :with_avatar, namespace: subgroup, description: 'bar') }

    it 'shows Organization structured markup', :js do
      visit path
      wait_for_all_requests

      aggregate_failures do
        expect(page).to have_selector('.content[itemscope][itemtype="https://schema.org/Organization"]')

        page.within('.group-home-panel') do
          expect(page).to have_selector('[itemprop="logo"]')
          expect(page).to have_selector('[itemprop="name"]', text: group.name)
          expect(page).to have_selector('[itemprop="description"]', text: group.description)
        end

        page.within('[itemprop="owns"][itemtype="https://schema.org/SoftwareSourceCode"]') do
          expect(page).to have_selector('[itemprop="image"]')
          expect(page).to have_selector('[itemprop="name"]', text: project.name)
          expect(page).to have_selector('[itemprop="description"]', text: project.description)
        end

        # Finding the subgroup row and expanding it
        click_group_caret(subgroup)
        within_testid("groups-list-item-#{subgroup.id}") do
          expect(page).to have_selector('[itemprop="logo"]')
          expect(page).to have_selector('[itemprop="name"]', text: subgroup.name)
          expect(page).to have_selector('[itemprop="description"]', text: subgroup.description)

          page.within('[itemprop="owns"][itemtype="https://schema.org/SoftwareSourceCode"]') do
            expect(page).to have_selector('[itemprop="image"]')
            expect(page).to have_selector('[itemprop="name"]', text: subproject.name)
            expect(page).to have_selector('[itemprop="description"]', text: subproject.description)
          end
        end
      end
    end

    it 'does not include structured markup in shared projects tab', :aggregate_failures, :js do
      other_project = create(:project, :public)
      other_project.project_group_links.create!(group: group)

      visit group_shared_path(group)
      wait_for_all_requests

      expect(page).not_to have_selector('[itemprop="owns"][itemtype="https://schema.org/SoftwareSourceCode"]')
    end
  end
end
