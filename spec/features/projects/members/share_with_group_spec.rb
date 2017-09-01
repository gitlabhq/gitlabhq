require 'spec_helper'

feature 'Project > Members > Share with Group', :js do
  include Select2Helper
  include ActionView::Helpers::DateHelper

  describe 'Share Lock' do
    let(:master) { create(:user) }
    let(:group) { create(:group) }
    let!(:other_group) { create(:group) }
    let(:project) { create(:project, namespace: group) }

    background do
      project.add_master(master)
      sign_in(master)
    end

    context 'when the group does not have "Share lock" enabled' do
      before do
        visit project_settings_members_path(project)

        click_on 'share-with-group-tab'

        select2 other_group.id, from: '#link_group_id'
        page.find('body').click
        find('.btn-create').trigger('click')
      end

      scenario 'the group link appears in the existing groups list' do
        page.within('.project-members-groups') do
          expect(page).to have_content(other_group.name)
        end
      end
    end

    context 'when the group has "Share lock" enabled' do
      before do
        group.update_column(:share_with_group_lock, true)
        visit project_settings_members_path(project)
      end

      scenario 'the "Share with group" tab does not exist' do
        expect(page).to have_selector('#add-member-tab')
        expect(page).not_to have_selector('#share-with-group-tab')
      end
    end
  end

  describe 'setting an expiration date for a group link' do
    let(:master) { create(:user) }
    let(:project) { create(:project) }
    let!(:group) { create(:group) }

    around do |example|
      Timecop.freeze { example.run }
    end

    before do
      project.add_master(master)
      sign_in(master)

      visit project_settings_members_path(project)

      click_on 'share-with-group-tab'

      select2 group.id, from: '#link_group_id'

      fill_in 'expires_at_groups', with: (Time.now + 4.5.days).strftime('%Y-%m-%d')
      page.find('body').click
      find('.btn-create').trigger('click')
    end

    scenario 'the group link shows the expiration time with a warning class' do
      page.within('.project-members-groups') do
        # Using distance_of_time_in_words_to_now because it is not the same as
        # subtraction, and this way avoids time zone issues as well
        expires_in_text = distance_of_time_in_words_to_now(project.project_group_links.first.expires_at)
        expect(page).to have_content(expires_in_text)
        expect(page).to have_selector('.text-warning')
      end
    end
  end

  describe 'the groups dropdown' do
    context 'with multiple groups to choose from' do
      let(:master) { create(:user) }
      let(:project) { create(:project) }
      let(:group) { create(:group) }

      background do
        project.add_master(master)
        sign_in(master)

        group_two = create(:group)
        group.add_owner(master)
        group_two.add_owner(master)

        visit project_settings_members_path(project)
        execute_script 'GroupsSelect.PER_PAGE = 1;'
        open_select2 '#link_group_id'
      end

      it 'should infinitely scroll' do
        expect(find('.select2-drop .select2-results')).to have_selector('.select2-result', count: 1)

        scroll_select2_to_bottom('.select2-drop .select2-results:visible')

        expect(find('.select2-drop .select2-results')).to have_selector('.select2-result', count: 2)
      end
    end

    context 'for a project in a nested group' do
      let(:master) { create(:user) }
      let(:group) { create(:group) }
      let!(:nested_group) { create(:group, parent: group) }
      let!(:another_group) { create(:group) }
      let!(:project) { create(:project, namespace: nested_group) }

      background do
        project.add_master(master)
        sign_in(master)
        group.add_master(master)
        another_group.add_master(master)
      end

      scenario 'the groups dropdown does not show ancestors', :nested_groups do
        visit project_settings_members_path(project)

        click_on 'share-with-group-tab'
        click_link 'Search for a group'

        page.within '.select2-drop' do
          expect(page).to have_content(another_group.name)
          expect(page).not_to have_content(group.name)
        end
      end
    end
  end
end
