# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project', feature_category: :source_code_management do
  include ProjectForksHelper
  include MobileHelpers

  describe 'template' do
    let(:user) { create(:user) }

    before do
      stub_feature_flags(new_project_creation_form: false)
      sign_in user
      visit new_project_path
    end

    shared_examples 'creates from template' do |template, sub_template_tab = nil|
      let(:selected_template) { page.find('.project-fields-form .selected-template') }

      choose_template_selector = '.choose-template'
      template_option_selector = '.template-option'
      template_name_selector = '.description strong'

      it "is created from template", :js do
        click_link 'Create from template'
        find(".project-template #{sub_template_tab}").click if sub_template_tab
        find("label[for=#{template.name}]").click
        fill_in("project_name", with: template.name)

        page.within '#content-body' do
          click_button "Create project"
        end

        expect(page).to have_content template.name
      end

      it 'is created using keyboard navigation', :js do
        click_link 'Create from template'

        first_template = first(template_option_selector)
        first_template_name = first_template.find(template_name_selector).text
        first_template.find(choose_template_selector).click

        expect(selected_template).to have_text(first_template_name)

        click_button "Change template"
        find("#built-in").click

        # Jumps down 1 template, skipping the `preview` buttons
        2.times do
          page.send_keys :tab
        end

        # Ensure the template with focus is selected
        project_name = "project from template"
        focused_template = page.find(':focus').ancestor(template_option_selector)
        focused_template_name = focused_template.find(template_name_selector).text
        focused_template.find(choose_template_selector).send_keys :enter
        fill_in "project_name", with: project_name

        expect(selected_template).to have_text(focused_template_name)

        page.within '#content-body' do
          click_button "Create project"
        end

        expect(page).to have_content project_name
      end
    end

    context 'create with project template' do
      it_behaves_like 'creates from template', Gitlab::ProjectTemplate.find(:rails)
    end

    context 'create with sample data template' do
      it_behaves_like 'creates from template', Gitlab::SampleDataTemplate.find(:sample)
    end
  end

  describe 'shows tip about push to create git command' do
    let(:user)    { create(:user) }

    before do
      stub_feature_flags(new_project_creation_form: false)
      sign_in user
      visit new_project_path
    end

    it 'shows the command in a popover', :js do
      click_link 'Show command'

      expect(page).to have_css('.popover #push-to-create-tip')
      expect(page).to have_content 'Private projects can be created in your personal namespace with:'
    end
  end

  describe 'description' do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      sign_in(project.first_owner)
    end

    it 'parses Markdown' do
      project.update_attribute(:description, 'This is **my** project')
      visit path
      expect(page).to have_css('.home-panel-description .home-panel-description-markdown p > strong')
    end

    it 'passes through html-pipeline' do
      project.update_attribute(:description, 'This project is the :poop:')
      visit path
      expect(page).to have_css('.home-panel-description .home-panel-description-markdown p > gl-emoji')
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
      it 'displays "read more" link', :js do
        project.update_attribute(:description, "This is **my** project\n\nA\n\nB\n\nC\n\nD\n\nE\n\nF\n\nG\n\nH\n\nI\n\nJ\nK\n\nL\n\nM\n\nN\n\nEnd test.")
        visit path

        expect(page).to have_css('.home-panel-description .js-read-more-trigger')
      end
    end

    context 'page description' do
      before do
        project.update_attribute(:description, '**Lorem** _ipsum_ dolor sit [amet](https://example.com)')
        visit path
      end

      it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'
    end
  end

  describe 'project topics' do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      sign_in(project.first_owner)
      visit path
    end

    it 'shows project topics' do
      project.update_attribute(:topic_list, 'topic1')

      visit path

      expect(page).to have_selector('[data-testid="project_topic_list"]')
      expect(page).to have_link('topic1', href: topic_explore_projects_path(topic_name: 'topic1'))
    end

    it 'shows up to 3 project topics' do
      project.update_attribute(:topic_list, 'topic1, topic2, topic3, topic4')

      visit path

      expect(page).to have_selector('[data-testid="project_topic_list"]')
      expect(page).to have_link('topic1', href: topic_explore_projects_path(topic_name: 'topic1'))
      expect(page).to have_link('topic2', href: topic_explore_projects_path(topic_name: 'topic2'))
      expect(page).to have_link('topic3', href: topic_explore_projects_path(topic_name: 'topic3'))
      expect(page).to have_content('+ 1 more')
    end
  end

  describe 'copy clone URL to clipboard', :js do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      stub_feature_flags(directory_code_dropdown_updates: false)
      sign_in(project.first_owner)
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

  describe 'showing information about source of a project fork', :js do
    let(:user) { create(:user) }
    let(:base_project) { create(:project, :public, :repository) }
    let(:forked_project) { fork_project(base_project, user, repository: true) }

    before do
      sign_in user
    end

    it 'shows a link to the source project when it is available', :sidekiq_might_not_need_inline do
      visit project_path(forked_project)
      wait_for_requests

      expect(page).to have_content('Forked from')
      expect(page).to have_link(base_project.full_name)
    end

    it 'does not contain fork network information for the root project' do
      forked_project

      visit project_path(base_project)
      wait_for_requests

      expect(page).not_to have_content('In fork network of')
      expect(page).not_to have_content('Forked from')
    end

    it 'does not show the name of the deleted project when the source was deleted', :sidekiq_might_not_need_inline do
      forked_project
      Projects::DestroyService.new(base_project, base_project.first_owner).execute

      visit project_path(forked_project)
      wait_for_requests
      expect(page).to have_content('Forked from an inaccessible project')
    end

    context 'a fork of a fork' do
      let(:fork_of_fork) { fork_project(forked_project, user, repository: true) }

      it 'links to the base project if the source project is removed', :sidekiq_might_not_need_inline do
        fork_of_fork
        Projects::DestroyService.new(forked_project, user).execute

        visit project_path(fork_of_fork)
        wait_for_requests
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

      expect(page).not_to have_selector('[data-testid="alert-danger"]')
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
      click_button 'Delete project'

      expect(page).to have_selector '#confirm_name_input:focus'
    end

    it 'deletes a project', :sidekiq_inline do
      expect { remove_with_confirm('Delete project', project.path_with_namespace, 'Yes, delete project') }.to change { Project.count }.by(-1)
      expect(page).to have_content "Project '#{project.full_name}' is being deleted."
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
      submodule = find_link('645f6c4c')

      expect(submodule[:href]).to eq('https://gitlab.com/gitlab-org/gitlab-grack/-/tree/645f6c4c82fd3f5e06f67134450a570b795e55a6')
    end

    context 'for signed commit on default branch', :js do
      before do
        project.change_head('33f3729a45c02fc67d00adb1b8bca394b0e761d9')
      end

      it 'displays a GPG badge' do
        visit project_path(project)
        wait_for_requests

        expect(page).not_to have_selector '.js-loading-signature-badge'
        expect(page).to have_selector '.gl-badge.badge-muted'
      end
    end

    context 'for subgroups', :js do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }
      let(:project) { create(:project, :repository, group: subgroup) }

      it 'renders tree table without errors' do
        wait_for_requests

        expect(page).to have_selector('.tree-item')
        expect(page).not_to have_selector('[data-testid="alert-danger"]')
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

          expect(page).not_to have_selector '.gl-badge.js-loading-signature-badge'
          expect(page).to have_selector '.gl-badge.badge-muted'
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

    it_behaves_like 'dirty submit form', [{ form: '.js-general-settings-form', input: 'input[name="project[name]"]', submit: 'button[type="submit"]' }]
  end

  describe 'view for a user without an access to a repo' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }

    it 'does not contain default branch information in its content', :js do
      default_branch = 'merge-commit-analyze-side-branch'

      project.add_guest(user)
      project.change_head(default_branch)

      sign_in(user)
      visit project_path(project)

      page.within('#content-body') do
        lines_with_default_branch = page.html.lines.select { |line| line.include?(default_branch) }
        expect(lines_with_default_branch).to eq([])
      end
    end
  end

  context 'badges' do
    shared_examples 'show badges' do
      it 'renders the all badges' do
        expect(page).to have_selector('.project-badges a')

        badges.each do |badge|
          expect(page).to have_link(href: badge.rendered_link_url)
        end
      end
    end

    let(:user) { create(:user) }
    let(:badges) { project.badges }

    context 'has no badges' do
      let(:project) { create(:project, :repository) }

      before do
        sign_in(user)
        project.add_maintainer(user)
        visit project_path(project)
      end

      it 'does not render any badge' do
        expect(page).not_to have_selector('.project-badges')
      end
    end

    context 'only has group badges' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :repository, namespace: group) }

      before do
        create(:group_badge, group: project.group)

        sign_in(user)
        project.add_maintainer(user)
        visit project_path(project)
      end

      it_behaves_like 'show badges'
    end

    context 'only has project badges' do
      let(:project) { create(:project, :repository) }

      before do
        create(:project_badge, project: project)

        sign_in(user)
        project.add_maintainer(user)
        visit project_path(project)
      end

      it_behaves_like 'show badges'
    end

    context 'has both group and project badges' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :repository, namespace: group) }

      before do
        create(:project_badge, project: project)
        create(:group_badge, group: project.group)

        sign_in(user)
        project.add_maintainer(user)
        visit project_path(project)
      end

      it_behaves_like 'show badges'
    end
  end

  def remove_with_confirm(button_text, confirm_with, confirm_button_text = 'Confirm')
    click_button button_text
    fill_in 'confirm_name_input', with: confirm_with
    click_button confirm_button_text
  end
end
