# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item linked items', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let(:work_items_path) { project_work_item_path(project, work_item.iid) }
  let_it_be(:task) { create(:work_item, :task, project: project, title: 'Task 1') }
  let_it_be(:milestone) { create(:milestone, project: project, title: '1.0') }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:objective) do
    create(:work_item, :objective, project: project, milestone: milestone,
      title: 'Objective 1', labels: [label])
  end

  context 'for signed in user' do
    let(:token_input_selector) { '[data-testid="work-item-token-select-input"] .gl-token-selector-input' }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)

      stub_feature_flags(work_items: true)
      stub_feature_flags(linked_work_items: true)

      visit work_items_path

      wait_for_requests
    end

    it 'are not displayed when issue does not have work item links', :aggregate_failures do
      page.within('.work-item-relationships') do
        expect(page).to have_selector('[data-testid="link-item-add-button"]')
        expect(page).not_to have_selector('[data-testid="link-work-item-form"]')
        expect(page).not_to have_selector('[data-testid="work-item-linked-items-list"]')
      end
    end

    it 'toggles widget body', :aggregate_failures do
      page.within('.work-item-relationships') do
        expect(page).to have_selector('[data-testid="widget-body"]')

        click_button 'Collapse'

        expect(page).not_to have_selector('[data-testid="widget-body"]')

        click_button 'Expand'

        expect(page).to have_selector('[data-testid="widget-body"]')
      end
    end

    it 'toggles form', :aggregate_failures do
      page.within('.work-item-relationships') do
        expect(page).not_to have_selector('[data-testid="link-work-item-form"]')

        click_button 'Add'

        expect(page).to have_selector('[data-testid="link-work-item-form"]')

        click_button 'Cancel'

        expect(page).not_to have_selector('[data-testid="link-work-item-form"]')
      end
    end

    it 'links a new item with work item text', :aggregate_failures do
      verify_linked_item_added(task.title)
    end

    it 'links a new item with work item iid', :aggregate_failures do
      verify_linked_item_added(task.iid)
    end

    it 'links a new item with work item wildcard iid', :aggregate_failures do
      verify_linked_item_added("##{task.iid}")
    end

    it 'links a new item with work item reference', :aggregate_failures do
      verify_linked_item_added(task.to_reference(full: true))
    end

    it 'links a new item with work item url', :aggregate_failures do
      verify_linked_item_added("#{task.project.web_url}/-/work_items/#{task.iid}")
    end

    it 'removes a linked item', :aggregate_failures do
      page.within('.work-item-relationships') do
        click_button 'Add'

        within_testid('link-work-item-form') do
          expect(page).to have_button('Add', disabled: true)
          find_by_testid('work-item-token-select-input').set(task.title)
          wait_for_all_requests
          click_button task.title

          expect(page).to have_button('Add', disabled: false)

          click_button 'Add'

          wait_for_all_requests
        end

        expect(find('.work-items-list')).to have_content('Task 1')

        find_by_testid('links-child').hover
        find_by_testid('remove-work-item-link').click

        wait_for_all_requests

        expect(page).not_to have_content('Task 1')
      end
    end

    it 'passes axe automated accessibility testing for linked items empty state' do
      expect(page).to be_axe_clean.within('.work-item-relationships').skipping :'link-in-text-block'
    end

    it 'passes axe automated accessibility testing for linked items' do
      page.within('.work-item-relationships') do
        click_button 'Add'

        find_by_testid('work-item-token-select-input').set(objective.title)
        wait_for_all_requests

        form_selector = '.work-item-relationships'
        expect(page).to be_axe_clean.within(form_selector).skipping :'aria-input-field-name',
          :'aria-required-children'

        within_testid('link-work-item-form') do
          click_button objective.title

          click_button 'Add'
        end

        wait_for_all_requests

        expect(page).to be_axe_clean.within(form_selector)
      end
    end
  end

  def verify_linked_item_added(input)
    page.within('.work-item-relationships') do
      click_button 'Add'

      within_testid('link-work-item-form') do
        expect(page).to have_button('Add', disabled: true)

        find(token_input_selector).set(input)
        wait_for_all_requests

        click_button task.title

        expect(page).to have_button('Add', disabled: false)

        click_button 'Add'

        wait_for_all_requests
      end

      expect(find('.work-items-list')).to have_content('Task 1')
    end
  end
end
