# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates work items', :js, feature_category: :team_planning do
  include ListboxHelpers
  include WorkItemsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: user) }

  before do
    sign_in(user)
  end

  context 'when on new work items page' do
    before do
      visit "#{project_path(project)}/-/work_items/new"
    end

    context 'when creating an issue' do
      it_behaves_like 'creates work item with widgets from new page', 'issue', %w[
        work-item-title-input
        work-item-description-wrapper
        work-item-assignees
        work-item-labels
        work-item-milestone
      ]

      context 'when using keyboard shortcuts' do
        it 'supports label shortcuts' do
          find('body').native.send_key('l')

          expect(find('.js-labels')).to have_selector('.gl-new-dropdown-panel')
        end
      end
    end
  end

  context 'when on project work items list page' do
    before do
      visit project_work_items_path(project)
    end

    context 'when creating an work item' do
      let_it_be(:label) { create(:label, title: 'Label 1', project: project) }
      let_it_be(:milestone) { create(:milestone, project: project, title: 'Milestone') }
      let(:issuable_container) { '[data-testid="issuable-container"]' }

      before do
        click_link 'New item'
      end

      it_behaves_like 'creates work item with widgets from a modal', 'issue', %w[
        work-item-title-input
        work-item-description-wrapper
        work-item-assignees
        work-item-labels
        work-item-milestone
      ]

      it 'renders metadata as set during work item creation' do
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(125)

        select_work_item_type('Issue')

        fill_work_item_title('Issue with metadata')

        assign_work_item_to_yourself

        set_work_item_label(label.title)

        set_work_item_milestone(milestone.title)

        create_work_item_with_type('issue')

        wait_for_all_requests

        within(all(issuable_container)[0]) do
          expect(page).to have_link(milestone.title)
            .and have_link(label.name)
            .and have_link(user.name, href: user_path(user))
        end
      end
    end
  end
end
