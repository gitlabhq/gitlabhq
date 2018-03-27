require 'spec_helper'

feature 'Project > Members > Share with Group', :js do
  include Select2Helper
  include ActionView::Helpers::DateHelper

  let(:master) { create(:user) }

  describe 'Share with group lock' do
    shared_examples 'the project can be shared with groups' do
      scenario 'the "Share with group" tab exists' do
        visit project_settings_members_path(project)
        expect(page).to have_selector('#share-with-group-tab')
      end
    end

    shared_examples 'the project cannot be shared with groups' do
      scenario 'the "Share with group" tab does not exist' do
        visit project_settings_members_path(project)
        expect(page).to have_selector('#add-member-tab')
        expect(page).not_to have_selector('#share-with-group-tab')
      end
    end

    context 'for a project in a root group' do
      let!(:group_to_share_with) { create(:group) }
      let(:project) { create(:project, namespace: create(:group)) }

      background do
        project.add_master(master)
        sign_in(master)
      end

      context 'when the group has "Share with group lock" disabled' do
        it_behaves_like 'the project can be shared with groups'

        scenario 'the project can be shared with another group' do
          visit project_settings_members_path(project)

          click_on 'share-with-group-tab'

          select2 group_to_share_with.id, from: '#link_group_id'
          page.find('body').click
          find('.btn-create').click

          page.within('.project-members-groups') do
            expect(page).to have_content(group_to_share_with.name)
          end
        end
      end

      context 'when the group has "Share with group lock" enabled' do
        before do
          project.namespace.update_column(:share_with_group_lock, true)
        end

        it_behaves_like 'the project cannot be shared with groups'
      end
    end

    context 'for a project in a subgroup', :nested_groups do
      let!(:group_to_share_with) { create(:group) }
      let(:root_group) { create(:group) }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:project) { create(:project, namespace: subgroup) }

      background do
        project.add_master(master)
        sign_in(master)
      end

      context 'when the root_group has "Share with group lock" disabled' do
        context 'when the subgroup has "Share with group lock" disabled' do
          it_behaves_like 'the project can be shared with groups'
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end
      end

      context 'when the root_group has "Share with group lock" enabled' do
        before do
          root_group.update_column(:share_with_group_lock, true)
        end

        context 'when the subgroup has "Share with group lock" disabled (parent overridden)' do
          it_behaves_like 'the project can be shared with groups'
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end
      end
    end
  end

  describe 'setting an expiration date for a group link' do
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
      click_on 'share-with-group-tab'
      find('.btn-create').click
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
      let(:project) { create(:project) }

      background do
        project.add_master(master)
        sign_in(master)

        create(:group).add_owner(master)
        create(:group).add_owner(master)

        visit project_settings_members_path(project)

        click_link 'Share with group'

        find('.ajax-groups-select.select2-container')

        execute_script 'GROUP_SELECT_PER_PAGE = 1;'
        open_select2 '#link_group_id'
      end

      it 'should infinitely scroll' do
        expect(find('.select2-drop .select2-results')).to have_selector('.select2-result', count: 1)

        scroll_select2_to_bottom('.select2-drop .select2-results:visible')

        expect(find('.select2-drop .select2-results')).to have_selector('.select2-result', count: 2)
      end
    end

    context 'for a project in a nested group' do
      let(:group) { create(:group) }
      let!(:nested_group) { create(:group, parent: group) }
      let!(:group_to_share_with) { create(:group) }
      let!(:project) { create(:project, namespace: nested_group) }

      background do
        project.add_master(master)
        sign_in(master)
        group.add_master(master)
        group_to_share_with.add_master(master)
      end

      scenario 'the groups dropdown does not show ancestors', :nested_groups do
        visit project_settings_members_path(project)

        click_on 'share-with-group-tab'
        click_link 'Search for a group'

        page.within '.select2-drop' do
          expect(page).to have_content(group_to_share_with.name)
          expect(page).not_to have_content(group.name)
        end
      end
    end
  end
end
