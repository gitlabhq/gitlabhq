# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Projects", feature_category: :groups_and_projects do
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers
  include ListboxHelpers
  include MobileHelpers

  let_it_be_with_reload(:user) { create :user }
  let_it_be_with_reload(:project) { create(:project, :with_namespace_settings) }
  let_it_be_with_reload(:admin) { create(:admin, timezone: 'Asia/Shanghai') }
  let(:current_user) { admin }

  before do
    sign_in(current_user)
    enable_admin_mode!(current_user)
  end

  describe 'when membership is set to expire', :js do
    it 'renders relative time' do
      expire_time = Time.current + 2.days
      current_user.update!(time_display_relative: true)
      project.add_member(user, Gitlab::Access::REPORTER, expires_at: expire_time)

      visit admin_project_path(project)

      expect(page).to have_content(/Expires in \d day/)
    end

    it 'renders absolute time' do
      expire_time = Time.current.tomorrow.middle_of_day
      current_user.update!(time_display_relative: false)
      project.add_member(user, Gitlab::Access::REPORTER, expires_at: expire_time)

      visit admin_project_path(project)

      expect(page).to have_content("Expires on #{expire_time.strftime('%b %-d')}")
    end
  end

  describe "GET /admin/projects" do
    context 'for an admin' do
      before do
        expect(project).to be_persisted
        visit admin_projects_path
      end

      context 'for "jh transition banner" part' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(false)
          allow(::Gitlab).to receive(:jh?).and_return(false)
        end

        it 'shows the banner class ".js-jh-transition-banner"' do
          expect(page).to have_selector('.js-jh-transition-banner')
          expect(page).to have_selector("[data-feature-name='transition_to_jihu_callout']")
          expect(page).to have_selector("[data-user-preferred-language='en']")
        end
      end

      it 'renders projects tabs list', :js do
        expect(page).to have_selector('.gl-tabs')
        expect(page).to have_selector('.vue-filtered-search-bar-container')
        expect(page).to have_content(project.name)
      end
    end

    context 'when `admin_projects_vue` is disabled' do
      let_it_be(:archived_project) { create :project, :public, :archived }

      before do
        stub_feature_flags(admin_projects_vue: false)

        expect(project).to be_persisted
        visit admin_projects_path
      end

      it "renders the correct path" do
        expect(page).to have_current_path(admin_projects_path, ignore_query: true)
      end

      it 'renders all projects', :js do
        find(:css, '#sort-projects-dropdown').click
        click_link 'Show archived projects'

        expect(page).to have_content(project.name)
        expect(page).to have_content(archived_project.name)
        expect(page).to have_xpath("//span[@class='gl-badge badge badge-pill badge-info gl-mr-3']", text: 'Archived')
      end

      it 'renders projects list without archived project' do
        expect(page).to have_content(project.name)
        expect(page).not_to have_content(archived_project.name)
      end

      it 'has project edit and delete button' do
        page.within('.project-row') do
          expect(page).to have_link 'Edit'
          expect(page).to have_button 'Delete'
        end
      end

      context 'when "Show archived projects only" is clicked' do
        it 'renders only archived projects', :js do
          find(:css, '#sort-projects-dropdown').click
          click_link 'Show archived projects only'

          expect(page).to have_content(archived_project.name)
          expect(page).not_to have_content(project.name)
        end
      end
    end
  end

  describe "GET /admin/projects/:namespace_id/:id" do
    let_it_be(:access_request) { create(:project_member, :access_request, project: project) }

    shared_examples 'renders project edit page' do
      it "has project info", :aggregate_failures do
        expect(page).to have_current_path admin_project_path(project), ignore_query: true
        expect(page).to have_content(project.path)
        expect(page).to have_content(project.name)
        expect(page).to have_content(project.full_name)
        expect(page).to have_content(project.creator.name)
        expect(page).to have_content(project.id)
      end

      it 'shows access requests with link to manage access' do
        within_testid('access-requests') do
          expect(page).to have_content access_request.user.name
          expect(page).to have_link 'Manage access', href: project_project_members_path(project, tab: 'access_requests')
        end
      end

      it 'shows transfer project and repository check sections' do
        expect(page).to have_content('Transfer project')
        expect(page).to have_content('Repository check')
      end

      it 'has project edit' do
        page.within('.content') do
          expect(page).to have_link 'Edit'
        end
      end
    end

    context 'for an admin', :js do
      before do
        visit admin_projects_path
        click_link project.name_with_namespace
      end

      it_behaves_like 'renders project edit page'

      context 'when `admin_projects_vue` is disabled' do
        before do
          stub_feature_flags(admin_projects_vue: false)

          expect(project).to be_persisted
          visit admin_projects_path
          click_link project.name
        end

        it_behaves_like 'renders project edit page'
      end
    end
  end

  describe 'transfer project' do
    # The gitlab-shell transfer will fail for a project without a repository
    let(:project) { create(:project, :repository, :with_namespace_settings) }

    before do
      create(:group, name: 'Web')

      allow_next_instance_of(Projects::TransferService) do |instance|
        allow(instance).to receive(:move_uploads_to_new_namespace).and_return(true)
      end
    end

    it 'transfers project to group web', :js do
      visit admin_project_path(project)

      select_from_listbox 'group: web', from: 'Search for Namespace'
      click_button 'Transfer'

      expect(page).to have_content("Web / #{project.name}")
      expect(page).to have_content('Namespace: Web')
    end
  end

  describe 'admin adds themselves to the project', :js do
    before do
      project.add_maintainer(user)
    end

    it 'adds admin to the project as developer' do
      visit project_project_members_path(project)

      invite_member(current_user.name, role: 'Developer')

      expect(find_member_row(current_user)).to have_content('Developer')
    end
  end

  describe 'admin removes themselves from the project', :js do
    before do
      project.add_maintainer(user)
      project.add_developer(current_user)
    end

    it 'removes admin from the project' do
      visit project_project_members_path(project)

      expect(find_member_row(current_user)).to have_content('Developer')

      show_actions_for_username(current_user)
      click_button _('Leave project')

      within_modal do
        click_button _('Leave')
      end

      expect(page).to have_current_path(dashboard_projects_path, ignore_query: true, url: false)
    end
  end

  describe 'project edit', :js do
    it 'shows breadcrumbs' do
      project_params = { id: project.to_param, namespace_id: project.namespace.to_param }
      visit edit_admin_namespace_project_path(project_params)

      expect(page_breadcrumbs).to include({ text: 'Admin area', href: admin_root_path },
        { text: 'Projects', href: admin_projects_path },
        { text: project.full_name, href: admin_namespace_project_path(project_params) },
        { text: 'Edit', href: edit_admin_namespace_project_path(project_params) })
    end

    it 'updates project details' do
      project = create(:project, :private, name: 'Garfield', description: 'Funny Cat')

      visit edit_admin_namespace_project_path({ id: project.to_param, namespace_id: project.namespace.to_param })

      aggregate_failures do
        expect(page).to have_content(project.name)
        expect(page).to have_content(project.description)
      end

      fill_in 'Project name', with: 'Scooby-Doo'
      fill_in 'Project description (optional)', with: 'Funny Dog'

      click_button 'Save changes'

      visit edit_admin_namespace_project_path({ id: project.to_param, namespace_id: project.namespace.to_param })

      aggregate_failures do
        expect(page).to have_content('Scooby-Doo')
        expect(page).to have_content('Funny Dog')
      end
    end
  end

  describe 'project runner registration edit' do
    it 'updates runner registration' do
      visit edit_admin_namespace_project_path({ id: project.to_param, namespace_id: project.namespace.to_param })

      expect(find_field('New project runners can be registered')).to be_checked

      uncheck 'New project runners can be registered'
      click_button 'Save changes'

      visit edit_admin_namespace_project_path({ id: project.to_param, namespace_id: project.namespace.to_param })

      expect(find_field('New project runners can be registered')).not_to be_checked
    end
  end
end
