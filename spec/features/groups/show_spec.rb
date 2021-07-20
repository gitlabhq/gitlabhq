# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group show page' do
  let(:group) { create(:group) }
  let(:path) { group_path(group) }

  context 'when signed in' do
    let(:user) do
      create(:group_member, :developer, user: create(:user), group: group ).user
    end

    before do
      sign_in(user)
      visit path
    end

    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"

    context 'when group does not exist' do
      let(:path) { group_path('not-exist') }

      it { expect(status_code).to eq(404) }
    end
  end

  context 'when signed out' do
    describe 'RSS' do
      before do
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed without a feed token"
    end

    context 'when group has a public project', :js do
      let!(:project) { create(:project, :public, namespace: group) }

      it 'renders public project' do
        visit path

        expect(page).to have_link group.name
        expect(page).to have_link project.name
      end
    end

    context 'when group has a private project', :js do
      let!(:project) { create(:project, :private, namespace: group) }

      it 'does not render private project' do
        visit path

        expect(page).to have_link group.name
        expect(page).not_to have_link project.name
      end
    end
  end

  context 'subgroup support' do
    let(:restricted_group) do
      create(:group, subgroup_creation_level: ::Gitlab::Access::OWNER_SUBGROUP_ACCESS)
    end

    let(:relaxed_group) do
      create(:group, subgroup_creation_level: ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
    end

    let(:owner) { create(:user) }
    let(:maintainer) { create(:user) }

    context 'for owners' do
      let(:path) { group_path(restricted_group) }

      before do
        restricted_group.add_owner(owner)
        sign_in(owner)
      end

      context 'when subgroups are supported' do
        it 'allows creating subgroups' do
          visit path

          expect(page).to have_link('New subgroup')
        end
      end
    end

    context 'for maintainers' do
      before do
        sign_in(maintainer)
      end

      context 'when subgroups are supported' do
        context 'when subgroup_creation_level is set to maintainers' do
          before do
            relaxed_group.add_maintainer(maintainer)
          end

          it 'allows creating subgroups' do
            path = group_path(relaxed_group)
            visit path

            expect(page).to have_link('New subgroup')
          end
        end

        context 'when subgroup_creation_level is set to owners' do
          before do
            restricted_group.add_maintainer(maintainer)
          end

          it 'does not allow creating subgroups' do
            path = group_path(restricted_group)
            visit path

            expect(page).not_to have_link('New subgroup')
          end
        end
      end
    end
  end

  context 'group has a project with emoji in description', :js do
    let(:user) { create(:user) }
    let!(:project) { create(:project, description: ':smile:', namespace: group) }

    before do
      group.add_owner(user)
      sign_in(user)
      visit path
    end

    it 'shows the project info' do
      expect(page).to have_content(project.title)
      expect(page).to have_emoji('smile')
    end
  end

  context 'where group has projects' do
    let(:user) { create(:user) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'allows users to sorts projects by most stars', :js do
      project1 = create(:project, namespace: group, star_count: 2)
      project2 = create(:project, namespace: group, star_count: 3)
      project3 = create(:project, namespace: group, star_count: 0)

      visit group_path(group, sort: :stars_desc)

      expect(find('.group-row:nth-child(1) .namespace-title > a')).to have_content(project2.title)
      expect(find('.group-row:nth-child(2) .namespace-title > a')).to have_content(project1.title)
      expect(find('.group-row:nth-child(3) .namespace-title > a')).to have_content(project3.title)
    end
  end

  context 'notification button', :js do
    let(:maintainer) { create(:user) }
    let!(:project)   { create(:project, namespace: group) }

    before do
      group.add_maintainer(maintainer)
      sign_in(maintainer)
    end

    it 'is enabled by default' do
      visit path

      expect(page).to have_selector('[data-testid="notification-dropdown"] button:not(.disabled)')
    end

    it 'is disabled if emails are disabled' do
      group.update_attribute(:emails_disabled, true)
      visit path

      expect(page).to have_selector('[data-testid="notification-dropdown"] .disabled')
    end
  end

  context 'page og:description' do
    let(:group) { create(:group, description: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)') }
    let(:maintainer) { create(:user) }

    before do
      group.add_maintainer(maintainer)
      sign_in(maintainer)
      visit path
    end

    it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'
  end

  context 'structured schema markup' do
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
        el = find('[itemprop="subOrganization"][itemtype="https://schema.org/Organization"]')
        el.click
        wait_for_all_requests
        page.within(el) do
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

    it 'does not include structured markup in shared projects tab', :js do
      other_project = create(:project, :public)
      other_project.project_group_links.create!(group: group)

      visit group_shared_path(group)
      wait_for_all_requests

      expect(page).to have_selector('li.group-row')
      expect(page).not_to have_selector('[itemprop="owns"][itemtype="https://schema.org/SoftwareSourceCode"]')
    end

    it 'does not include structured markup in archived projects tab', :js do
      project.update!(archived: true)

      visit group_archived_path(group)
      wait_for_all_requests

      expect(page).to have_selector('li.group-row')
      expect(page).not_to have_selector('[itemprop="owns"][itemtype="https://schema.org/SoftwareSourceCode"]')
    end
  end
end
