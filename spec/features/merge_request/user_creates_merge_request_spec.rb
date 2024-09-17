# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates a merge request', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include ListboxHelpers

  shared_examples 'creates a merge request' do
    specify do
      visit(project_new_merge_request_path(project))

      compare_source_and_target('fix', 'feature')

      page.within('.merge-request-form') do
        expect(page.find('#merge_request_description')['placeholder']).to eq 'Describe the goal of the changes and what reviewers should be aware of.'
      end

      fill_in('Title', with: title)
      click_button('Create merge request')

      page.within('.merge-request') do
        expect(page).to have_content(title)
      end
    end
  end

  shared_examples 'renders not found' do
    specify do
      visit project_new_merge_request_path(project)

      expect(page).to have_title('Not Found')
      expect(page).to have_content('Page not found')
    end
  end

  context 'when user is a direct project member' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    let(:title) { 'Some feature' }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it_behaves_like 'creates a merge request'

    context 'with XSS branch name' do
      before do
        project.repository.create_branch("<img/src='x'/onerror=alert('oops')>", 'master')
      end

      it 'does not execute the suspicious branch name', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/447484' do
        visit(project_new_merge_request_path(project))

        compare_source_and_target("<img/src='x'/onerror=alert('oops')>", 'feature')

        expect { page.driver.browser.switch_to.alert }.to raise_error(Selenium::WebDriver::Error::NoSuchAlertError)
      end
    end

    context 'to a forked project' do
      let(:forked_project) { fork_project(project, user, namespace: user.namespace, repository: true) }

      it 'creates a merge request', :sidekiq_might_not_need_inline do
        visit(project_new_merge_request_path(forked_project))

        expect(page).to have_content('Source branch').and have_content('Target branch')
        expect(find('#merge_request_target_project_id', visible: false).value).to eq(project.id.to_s)

        click_button('Compare branches and continue')

        expect(page).to have_content('You must select source and target branch')

        select_project('.js-source-project', forked_project)
        select_project('.js-target-project', project)
        select_branch('.js-source-branch', 'fix')

        click_button('Compare branches and continue')

        expect(page).to have_text _('New merge request')

        page.within('form#new_merge_request') do
          fill_in('Title', with: title)
        end

        expect(find('.js-assignee-search')['data-project-id']).to eq(project.id.to_s)
        find('.js-assignee-search').click

        page.within('.dropdown-menu-user') do
          expect(page).to have_content('Unassigned')
                      .and have_content(user.name)
                      .and have_content(project.users.first.name)
        end
        find('.js-assignee-search').click

        click_button('Create merge request')

        expect(page).to have_content(title).and have_content("requested to merge #{forked_project.full_path}:fix into master")
      end
    end
  end

  context 'when user is an inherited member from the group' do
    let_it_be(:group) { create(:group, :public) }

    let(:user) { create(:user) }

    context 'when project is public and merge requests are private' do
      let_it_be(:project) do
        create(
          :project,
          :public,
          :repository,
          group: group,
          merge_requests_access_level: ProjectFeature::DISABLED
        )
      end

      context 'and user is a guest' do
        before do
          group.add_guest(user)
          sign_in(user)
        end

        it_behaves_like 'renders not found'
      end
    end

    context 'when project is private' do
      let_it_be(:project) { create(:project, :private, :repository, group: group) }

      context 'and user is a guest' do
        before do
          group.add_guest(user)
          sign_in(user)
        end

        it_behaves_like 'renders not found'
      end
    end
  end

  context 'when source and target both have a commit with the same content' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    let(:title) { 'Some feature' }

    before do
      project.add_maintainer(user)
      sign_in(user)

      # create a commit with identical content on source and target
      project.repository.create_file(user, 'bbb.txt', 'zzzz', message: 'Commit on target', branch_name: 'feature')
      project.repository.create_file(user, 'bbb.txt', 'zzzz', message: 'Commit on src', branch_name: 'fix')
    end

    it "contains the correct changes count", :sidekiq_inline do
      visit(project_new_merge_request_path(project))

      compare_source_and_target('fix', 'feature')

      fill_in('Title', with: title)
      click_button('Create merge request')

      page.within('.diffs-tab') do
        expect(page).to have_content('Changes 2')
      end

      click_on 'Changes'
      wait_for_requests

      page.within('.diffs-tab') do
        expect(page).to have_content('Changes 2')
      end
    end
  end

  private

  def compare_source_and_target(source_branch, target_branch)
    select_branch('.js-source-branch', source_branch)
    select_branch('.js-target-branch', target_branch)

    click_button('Compare branches')
  end

  def select_project(selector, project)
    first(selector).click

    wait_for_requests

    find('.gl-listbox-search-input').set(project.full_path)
    select_listbox_item(project.full_path)
  end

  def select_branch(selector, branch)
    first(selector).click

    wait_for_requests

    find('.gl-listbox-search-input').set(branch)
    select_listbox_item(branch, exact_text: true)
  end
end
