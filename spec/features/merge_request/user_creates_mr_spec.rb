# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User creates MR', feature_category: :code_review_workflow do
  include ProjectForksHelper

  before do
    stub_licensed_features(multiple_merge_request_assignees: false)
  end

  shared_examples 'a creatable merge request with visible selected labels' do
    include WaitForRequests
    include ListboxHelpers

    it 'creates new merge request', :js do
      find_by_testid('assignee-ids-dropdown-toggle').click
      page.within '.dropdown-menu-user' do
        click_link user2.name
      end

      expect(find('input[name="merge_request[assignee_ids][]"]', visible: false).value).to match(user2.id.to_s)
      within_testid('assignee-ids-dropdown-toggle') do
        expect(page).to have_content user2.name
      end

      click_link 'Assign to me'

      expect(find('input[name="merge_request[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)
      within_testid('assignee-ids-dropdown-toggle') do
        expect(page).to have_content user.name
      end

      click_button 'Select milestone'
      click_button milestone.title
      expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(page).to have_button milestone.title

      click_button _('Select label')
      wait_for_all_requests
      within_testid('sidebar-labels') do
        click_button label.title
        click_button label2.title
        click_button _('Close')
        wait_for_requests
        within_testid('embedded-labels-list') do
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end

      click_button 'Create merge request'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content user.name
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end
    end

    it 'updates the branches when selecting a new target project', :js do
      target_project_member = target_project.first_owner
      ::Branches::CreateService.new(target_project, target_project_member)
        .execute('a-brand-new-branch-to-test', 'master')

      visit project_new_merge_request_path(source_project)

      find('.js-source-branch').click
      select_listbox_item('master')

      first('.js-target-project').click
      select_listbox_item(target_project.full_path)

      wait_for_requests

      first('.js-target-branch').click

      find('.gl-listbox-search-input').set('a-brand-new-branch-to-test')

      wait_for_requests

      expect_listbox_item('a-brand-new-branch-to-test')
    end
  end

  context 'non-fork merge request' do
    include_context 'merge request create context'
    it_behaves_like 'a creatable merge request with visible selected labels'
  end

  context 'from a forked project' do
    let(:canonical_project) { create(:project, :public, :repository) }

    let(:source_project) do
      fork_project(canonical_project, user,
        repository: true,
        namespace: user.namespace)
    end

    context 'to canonical project' do
      include_context 'merge request create context'
      it_behaves_like 'a creatable merge request with visible selected labels'
    end

    context 'to another forked project' do
      let(:target_project) do
        fork_project(canonical_project, user,
          repository: true,
          namespace: user.namespace)
      end

      include_context 'merge request create context'
      it_behaves_like 'a creatable merge request with visible selected labels'
    end
  end

  context 'source project', :js do
    let(:user) { create(:user) }
    let(:target_project) { create(:project, :public, :repository) }
    let(:source_project) { target_project }

    before do
      source_project.add_maintainer(user)

      sign_in(user)
      visit project_new_merge_request_path(
        target_project,
        merge_request: {
          source_project_id: source_project.id,
          target_project_id: target_project.id
        })
    end

    it 'filters source project' do
      find('.js-source-project').click
      find('.gl-listbox-search-input').set('source')

      expect(first('.merge-request-select .gl-new-dropdown-panel')).not_to have_content(source_project.name)
    end
  end
end
