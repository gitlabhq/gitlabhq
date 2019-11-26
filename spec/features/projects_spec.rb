# frozen_string_literal: true

require 'spec_helper'

describe 'Project' do
  include ProjectForksHelper
  include MobileHelpers

  describe 'creating from template' do
    let(:user) { create(:user) }
    let(:template) { Gitlab::ProjectTemplate.find(:rails) }

    before do
      sign_in user
      visit new_project_path
    end

    it "allows creation from templates", :js do
      find('#create-from-template-tab').click
      find("label[for=#{template.name}]").click
      fill_in("project_name", with: template.name)

      page.within '#content-body' do
        click_button "Create project"
      end

      expect(page).to have_content template.name
    end
  end

  describe 'shows tip about push to create git command' do
    let(:user)    { create(:user) }

    before do
      sign_in user
      visit new_project_path
    end

    it 'shows the command in a popover', :js do
      page.within '.profile-settings-sidebar' do
        click_link 'Show command'
      end

      expect(page).to have_css('.popover .push-to-create-popover #push_to_create_tip')
      expect(page).to have_content 'Private projects can be created in your personal namespace with:'
    end
  end

  describe 'description' do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      sign_in(create(:admin))
    end

    it 'parses Markdown' do
      project.update_attribute(:description, 'This is **my** project')
      visit path
      expect(page).to have_css('.home-panel-description > .home-panel-description-markdown > p > strong')
    end

    it 'passes through html-pipeline' do
      project.update_attribute(:description, 'This project is the :poop:')
      visit path
      expect(page).to have_css('.home-panel-description > .home-panel-description-markdown > p > gl-emoji')
    end

    it 'sanitizes unwanted tags' do
      project.update_attribute(:description, "```\ncode\n```")
      visit path
      expect(page).not_to have_css('.home-panel-description code')
    end

    it 'permits `rel` attribute on links' do
      project.update_attribute(:description, 'https://google.com/')
      visit path
      expect(page).to have_css('.home-panel-description a[rel]')
    end

    context 'read more', :js do
      let(:read_more_selector)         { '.read-more-container' }
      let(:read_more_trigger_selector) { '.home-panel-home-desc .js-read-more-trigger' }

      it 'does not display "read more" link on desktop breakpoint' do
        project.update_attribute(:description, 'This is **my** project')
        visit path

        expect(find(read_more_trigger_selector, visible: false)).not_to be_visible
      end

      it 'displays "read more" link on mobile breakpoint' do
        project.update_attribute(:description, 'This is **my** project')
        visit path
        resize_screen_xs

        find(read_more_trigger_selector).click

        expect(page).to have_css('.home-panel-description .is-expanded')
      end
    end
  end

  describe 'project topics' do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      sign_in(create(:admin))
      visit path
    end

    it 'shows project topics' do
      project.update_attribute(:tag_list, 'topic1')

      visit path

      expect(page).to have_css('.home-panel-topic-list')
      expect(page).to have_link('Topic1', href: explore_projects_path(tag: 'topic1'))
    end

    it 'shows up to 3 project tags' do
      project.update_attribute(:tag_list, 'topic1, topic2, topic3, topic4')

      visit path

      expect(page).to have_css('.home-panel-topic-list')
      expect(page).to have_link('Topic1', href: explore_projects_path(tag: 'topic1'))
      expect(page).to have_link('Topic2', href: explore_projects_path(tag: 'topic2'))
      expect(page).to have_link('Topic3', href: explore_projects_path(tag: 'topic3'))
      expect(page).to have_content('+ 1 more')
    end
  end

  describe 'copy clone URL to clipboard', :js do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      sign_in(create(:admin))
      visit path
    end

    context 'desktop component' do
      it 'shows on md and larger breakpoints' do
        expect(find('.git-clone-holder')).to be_visible
        expect(find('.mobile-git-clone', visible: false)).not_to be_visible
      end
    end

    context 'mobile component' do
      it 'shows mobile component on sm and smaller breakpoints' do
        resize_screen_xs
        expect(find('.mobile-git-clone')).to be_visible
        expect(find('.git-clone-holder', visible: false)).not_to be_visible
      end
    end
  end

  describe 'remove forked relationship', :js do
    let(:user)    { create(:user) }
    let(:project) { fork_project(create(:project, :public), user, namespace_id: user.namespace) }

    before do
      sign_in user
      visit edit_project_path(project)
    end

    it 'removes fork' do
      expect(page).to have_content 'Remove fork relationship'

      remove_with_confirm('Remove fork relationship', project.path)

      expect(page).to have_content 'The fork relationship has been removed.'
      expect(project.reload.forked?).to be_falsey
      expect(page).not_to have_content 'Remove fork relationship'
    end
  end

  describe 'showing information about source of a project fork' do
    let(:user) { create(:user) }
    let(:base_project) { create(:project, :public, :repository) }
    let(:forked_project) { fork_project(base_project, user, repository: true) }

    before do
      sign_in user
    end

    it 'shows a link to the source project when it is available', :sidekiq_might_not_need_inline do
      visit project_path(forked_project)

      expect(page).to have_content('Forked from')
      expect(page).to have_link(base_project.full_name)
    end

    it 'does not contain fork network information for the root project' do
      forked_project

      visit project_path(base_project)

      expect(page).not_to have_content('In fork network of')
      expect(page).not_to have_content('Forked from')
    end

    it 'does not show the name of the deleted project when the source was deleted', :sidekiq_might_not_need_inline do
      forked_project
      Projects::DestroyService.new(base_project, base_project.owner).execute

      visit project_path(forked_project)

      expect(page).to have_content('Forked from an inaccessible project')
    end

    context 'a fork of a fork' do
      let(:fork_of_fork) { fork_project(forked_project, user, repository: true) }

      it 'links to the base project if the source project is removed', :sidekiq_might_not_need_inline do
        fork_of_fork
        Projects::DestroyService.new(forked_project, user).execute

        visit project_path(fork_of_fork)

        expect(page).to have_content("Forked from")
        expect(page).to have_link(base_project.full_name)
      end
    end
  end

  describe 'when the project repository is disabled', :js do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository_disabled, :repository, namespace: user.namespace) }

    before do
      sign_in(user)
      project.add_maintainer(user)
      visit project_path(project)
    end

    it 'does not show an error' do
      wait_for_requests

      expect(page).not_to have_selector('.flash-alert')
    end
  end

  describe 'removal', :js do
    let(:user)    { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      sign_in(user)
      project.add_maintainer(user)
      visit edit_project_path(project)
    end

    it 'focuses on the confirmation field' do
      click_button 'Remove project'

      expect(page).to have_selector '#confirm_name_input:focus'
    end

    it 'removes a project', :sidekiq_might_not_need_inline do
      expect { remove_with_confirm('Remove project', project.path) }.to change { Project.count }.by(-1)
      expect(page).to have_content "Project '#{project.full_name}' is in the process of being deleted."
      expect(Project.all.count).to be_zero
      expect(project.issues).to be_empty
      expect(project.merge_requests).to be_empty
    end
  end

  describe 'tree view (default view is set to Files)', :js do
    let(:user) { create(:user, project_view: 'files') }
    let(:project) { create(:forked_project_with_submodules) }

    before do
      project.add_maintainer(user)
      sign_in user
      visit project_path(project)
    end

    it 'has working links to files' do
      click_link('PROCESS.md')

      expect(page).to have_selector('.file-holder')
    end

    it 'has working links to directories' do
      click_link('encoding')

      expect(page).to have_selector('.breadcrumb-item', text: 'encoding')
    end

    it 'has working links to submodules' do
      click_link('645f6c4c')

      expect(page).to have_selector('.qa-branches-select', text: '645f6c4c82fd3f5e06f67134450a570b795e55a6')
    end

    context 'for signed commit on default branch', :js do
      before do
        project.change_head('33f3729a45c02fc67d00adb1b8bca394b0e761d9')
      end

      it 'displays a GPG badge' do
        visit project_path(project)
        wait_for_requests

        expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
        expect(page).to have_selector '.gpg-status-box.invalid'
      end
    end

    context 'for subgroups', :js do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }
      let(:project) { create(:project, :repository, group: subgroup) }

      it 'renders tree table without errors' do
        wait_for_requests

        expect(page).to have_selector('.tree-item')
        expect(page).not_to have_selector('.flash-alert')
      end

      context 'for signed commit' do
        before do
          repository = project.repository
          repository.write_ref("refs/heads/#{project.default_branch}", '33f3729a45c02fc67d00adb1b8bca394b0e761d9')
          repository.expire_branches_cache
        end

        it 'displays a GPG badge' do
          visit project_path(project)
          wait_for_requests

          expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
          expect(page).to have_selector '.gpg-status-box.invalid'
        end
      end
    end
  end

  describe 'activity view' do
    let(:user) { create(:user, project_view: 'activity') }
    let(:project) { create(:project, :repository) }

    before do
      project.add_maintainer(user)
      sign_in user
      visit project_path(project)
    end

    it 'loads activity', :js do
      expect(page).to have_selector('.event-item')
    end
  end

  context 'content is not cached after signing out', :js do
    let(:user) { create(:user, project_view: 'activity') }
    let(:project) { create(:project, :repository) }

    it 'does not load activity', :js do
      project.add_maintainer(user)
      sign_in(user)
      visit project_path(project)
      sign_out(user)

      page.evaluate_script('window.history.back()')

      expect(page).not_to have_selector('.event-item')
    end
  end

  describe 'edit' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:path) { edit_project_path(project) }

    before do
      project.add_maintainer(user)
      sign_in(user)
      visit path
    end

    it_behaves_like 'dirty submit form', [{ form: '.js-general-settings-form', input: 'input[name="project[name]"]' },
                                          { form: '.rspec-merge-request-settings', input: '#project_printing_merge_request_link_enabled' }]
  end

  def remove_with_confirm(button_text, confirm_with)
    click_button button_text
    fill_in 'confirm_name_input', with: confirm_with
    click_button 'Confirm'
  end
end
