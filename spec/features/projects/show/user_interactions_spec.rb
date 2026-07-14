# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User interactions', feature_category: :groups_and_projects do
  describe 'Project stars', :js, :with_current_organization do
    let_it_be(:project) { create(:project, :public, :repository) }

    context 'when user is signed in', :js do
      let(:user) { create(:user, organization: current_organization) }

      before do
        sign_in(user)
        visit(project_path(project))
      end

      it 'retains the star count even after a page reload' do
        star_project

        reload_page

        expect(page).to have_css('.star-count', text: 1)
      end

      it 'toggles the star' do
        star_project

        expect(page).to have_css('.star-count', text: 1)

        unstar_project

        expect(page).to have_css('.star-count', text: 0)
      end

      it 'validates starring a project' do
        project.add_owner(user)

        star_project

        visit(member_dashboard_projects_path)
        wait_for_requests

        expect(find_by_testid('stars-btn')).to have_content('1')
      end

      it 'validates un-starring a project' do
        project.add_owner(user)

        star_project

        unstar_project

        visit(member_dashboard_projects_path)
        wait_for_requests

        expect(find_by_testid('stars-btn')).to have_content('0')
      end
    end

    context 'when user is not signed in' do
      before do
        visit(project_path(project))
      end

      it 'does not allow to star a project' do
        expect(page).to have_css('.star-btn')
        expect(page).not_to have_css('.toggle-star')

        find('.star-btn').click

        expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      end
    end

    private

    def reload_page
      visit current_path
    end

    def star_project
      click_button(_('Star'))
      wait_for_requests
    end

    def unstar_project
      click_button(_('Unstar'))
      wait_for_requests
    end
  end

  describe 'Notifications', :js do
    let_it_be(:project) { create(:project, :public, :repository) }

    before do
      sign_in(project.first_owner)
    end

    def click_notifications_button
      find_by_testid('notification-dropdown').click
    end

    def click_notification_item(value)
      find("[data-testid='listbox-item-#{value}']").click
    end

    it 'changes the notification setting' do
      visit project_path(project)
      click_notifications_button
      click_notification_item(:mention)

      wait_for_requests

      click_notifications_button

      page.within find_by_testid('notification-dropdown') do
        expect(page.find('.gl-new-dropdown-item[aria-selected]')).to have_content('On mention')
        expect(page).to have_css('[data-testid="notifications-icon"]')
      end
    end

    it 'changes the notification setting to disabled' do
      visit project_path(project)
      click_notifications_button
      click_notification_item(:disabled)

      page.within find_by_testid('notification-dropdown') do
        expect(page).to have_css('[data-testid="notifications-off-icon"]')
      end
    end

    context 'custom notification settings' do
      let(:email_events) do
        [
          :new_note,
          :new_issue,
          :reopen_issue,
          :close_issue,
          :reassign_issue,
          :issue_due,
          :new_merge_request,
          :push_to_merge_request,
          :reopen_merge_request,
          :close_merge_request,
          :reassign_merge_request,
          :merge_merge_request,
          :failed_pipeline,
          :fixed_pipeline,
          :success_pipeline,
          :moved_project
        ]
      end

      it 'shows notification settings checkbox' do
        visit project_path(project)
        click_notifications_button
        click_notification_item(:custom)

        wait_for_requests

        page.within('#custom-notifications-modal') do
          email_events.each do |event_name|
            expect(page).to have_selector("[data-testid='notification-setting-#{event_name}']")
          end
        end
      end
    end

    context 'when project emails are disabled' do
      let_it_be(:project) { create(:project, :public, :repository, emails_enabled: false) }

      it 'is disabled' do
        visit project_path(project)
        expect(page).to have_selector('[data-testid="notification-dropdown"] .disabled', visible: :visible)
      end
    end
  end

  describe 'Collaboration links', :js do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:project1) { create(:project, :repository, :public) }
    let_it_be(:project2) { create(:project, :repository, :public) }
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    def find_new_menu_toggle
      find_by_testid('base-dropdown-toggle', visible: :all, text: 'Create new…')
    end

    def within_navigation_panel(&block)
      within('.super-topbar', &block)
    end

    context 'with developer user' do
      before_all do
        project1.add_developer(user)
      end

      it 'shows all the expected links' do
        visit project_path(project1)

        # The navigation bar
        within_navigation_panel do
          find_new_menu_toggle.click

          aggregate_failures 'dropdown links in the navigation bar' do
            expect(page).to have_button('New work item')
            expect(page).to have_link('New merge request')
            expect(page).to have_link('New snippet', href: new_project_snippet_path(project1))
          end

          find_new_menu_toggle.click
        end

        # The dropdown above the tree
        page.within('.tree-controls') do
          find('.add-to-tree').click

          aggregate_failures 'dropdown links above the repo tree' do
            expect(page).to have_button('New file')
            expect(page).to have_button('Upload file')
            expect(page).to have_button('New directory')
            expect(page).to have_button('New branch')
            expect(page).to have_button('New tag')
          end
        end

        # The Web IDE
        within_testid('code-dropdown') do
          click_button 'Code'
        end
        expect(page).to have_link('Web IDE')
      end

      it 'hides the links when the project is archived' do
        project1.update!(archived: true)

        visit project_path(project1)

        within_navigation_panel do
          find_new_menu_toggle.click

          aggregate_failures 'dropdown links' do
            expect(page).not_to have_link('New issue')
            expect(page).not_to have_link('New merge request')
            expect(page).not_to have_link('New snippet', href: new_project_snippet_path(project1))
          end

          find_new_menu_toggle.click
        end

        expect(page).not_to have_selector('[data-testid="add-to-tree"]')

        within_testid('code-dropdown') do
          click_button('Code')
          expect(page).not_to have_button('Edit')
          expect(page).not_to have_link('Web IDE')
        end
      end
    end

    context "Web IDE link" do
      where(:merge_requests_access_level, :user_level, :expect_ide_link) do
        ::ProjectFeature::DISABLED | :guest | false
        ::ProjectFeature::DISABLED | :developer | true
        ::ProjectFeature::PRIVATE | :guest | false
        ::ProjectFeature::PRIVATE | :developer | true
        ::ProjectFeature::ENABLED | :guest | true
        ::ProjectFeature::ENABLED | :developer | true
      end

      with_them do
        before do
          project1.project_feature.update!({ merge_requests_access_level: merge_requests_access_level })
          project1.add_member(user, user_level)
          visit project_path(project1)
        end

        it "updates Web IDE link" do
          within_testid('code-dropdown') do
            click_button 'Code'
          end
          expect(page.has_link?('Web IDE')).to be(expect_ide_link)
        end
      end
    end
  end

  describe 'Dropdown actions' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, :repository, group: group) }
    let_it_be(:selector) { 'projects-list-item-actions' }

    context 'when a user is signed in' do
      let_it_be_with_reload(:user) { create(:user) }

      context 'and the user is not a member of the project' do
        before do
          sign_in(user)
          visit project_path(project)
        end

        it 'shows correct items', :js, :aggregate_failures do
          click_dropdown

          within_testid(selector) do
            expect(page).not_to have_content('Leave project')
            expect(page).to have_content("Copy project ID: #{project.id}")
            expect(page).not_to have_content('Edit')
          end
        end
      end

      context 'and the user is added to the project' do
        before do
          project.add_member(user, role)
          sign_in(user)
          visit project_path(project)
        end

        context 'and the user has developer access' do
          let_it_be(:role) { :developer }

          it 'shows correct items', :js, :aggregate_failures do
            click_dropdown

            within_testid(selector) do
              expect(page).to have_content('Leave project')
              expect(page).to have_content("Copy project ID: #{project.id}")
              expect(page).not_to have_content('Edit')
            end
          end
        end

        context 'and the user has maintainer access' do
          let_it_be(:role) { :maintainer }

          it 'shows correct items', :js, :aggregate_failures do
            click_dropdown

            within_testid(selector) do
              expect(page).to have_content('Leave project')
              expect(page).to have_content("Copy project ID: #{project.id}")
              expect(page).to have_content('Edit')
            end
          end
        end
      end

      context 'and the user is added to the group' do
        before do
          group.add_member(user, role)
          sign_in(user)
          visit project_path(project)
        end

        context 'and the user has developer access' do
          let_it_be(:role) { :developer }

          it 'shows correct items', :js, :aggregate_failures do
            click_dropdown

            within_testid(selector) do
              expect(page).not_to have_content('Leave project')
              expect(page).to have_content("Copy project ID: #{project.id}")
              expect(page).not_to have_content('Edit')
            end
          end
        end

        context 'and the user has maintainer access' do
          let_it_be(:role) { :maintainer }

          it 'shows correct items', :js, :aggregate_failures do
            click_dropdown

            within_testid(selector) do
              expect(page).not_to have_content('Leave project')
              expect(page).to have_content("Copy project ID: #{project.id}")
              expect(page).to have_content('Edit')
            end
          end
        end
      end
    end

    context 'when a user is not signed in' do
      before do
        visit project_path(project)
      end

      it 'shows correct items', :js, :aggregate_failures do
        click_dropdown

        within_testid(selector) do
          expect(page).not_to have_content('Leave project')
          expect(page).to have_content("Copy project ID: #{project.id}")
          expect(page).not_to have_content('Edit')
        end
      end
    end

    def click_dropdown
      find_by_testid(selector).click
    end
  end
end
