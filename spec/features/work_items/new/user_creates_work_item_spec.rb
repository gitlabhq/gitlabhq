# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates work items', :js, feature_category: :team_planning do
  include WorkItemsHelpers
  include ListboxHelpers
  include RichTextEditorHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, developers: user, group: group) }

  before do
    sign_in(user)
  end

  context 'when opening modal from super sidebar' do
    using RSpec::Parameterized::TableSyntax

    before do
      visit project_path(project)
      find_by_testid('new-menu-toggle').click
      find_by_testid('new-work-item-trigger').click
      wait_for_all_requests
    end

    where(:type, :widgets) do
      'Issue'    | %w[work-item-title-input work-item-description-wrapper work-item-assignees
        work-item-labels work-item-milestone work-item-due-dates]
      'Incident' | %w[work-item-title-input work-item-description-wrapper work-item-assignees
        work-item-labels work-item-milestone]
      'Task'     | %w[work-item-title-input work-item-description-wrapper work-item-assignees
        work-item-labels work-item-milestone work-item-due-dates work-item-parent]
    end

    with_them do
      it 'creates a work item with expected widgets', :aggregate_failures do
        select_work_item_type(type)

        expect_work_item_widgets(widgets)

        fill_work_item_title("#{type} from sidebar")
        fill_work_item_description("#{type} description from sidebar")

        expect do
          create_work_item_with_type(type)
          wait_for_all_requests
        end.to change { project.work_items.count }.by(1)

        created_work_item = project.work_items.last
        expect(created_work_item.title).to eq("#{type} from sidebar")
        expect(created_work_item.description).to eq("#{type} description from sidebar")
      end
    end

    it 'closes the description suggestions on Escape and reaches the form only on a second Escape' do
      suggestions_dropdown = '[data-testid="content-editor-suggestions-dropdown"]'
      discard_prompt = 'Are you sure you want to cancel creating this issue?'

      fill_work_item_title('Keyboard draft')
      switch_to_content_editor
      type_in_content_editor 'Draft description :'

      expect(find(suggestions_dropdown)).to have_text('grinning')

      send_keys :escape

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).not_to have_text(discard_prompt)
      expect(page).to have_css('.create-work-item-modal')
      expect(find(content_editor_testid)).to have_text('Draft description :')

      send_keys :escape

      expect(page).to have_text(discard_prompt).or(have_no_css('.create-work-item-modal'))
    end
  end
end
