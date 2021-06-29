# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Activity > User sees design Activity', :js do
  include DesignManagementTestHelpers

  let_it_be(:uploader) { create(:user) }
  let_it_be(:editor) { create(:user) }
  let_it_be(:deleter) { create(:user) }

  def design_activity(user, action)
    [user.name, user.to_reference, action, 'design'].join(' ')
  end

  shared_examples 'being able to see design activity' do
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:design) { create(:design, issue: issue) }

    before_all do
      project.add_developer(user) # implicitly adds a project join event.
      common_attrs = { project: project, design: design }
      create(:design_event, :created, author: uploader, **common_attrs)
      create(:design_event, :updated, author: editor, **common_attrs)
      create(:design_event, :destroyed, author: deleter, **common_attrs)
    end

    before do
      enable_design_management
      sign_in(user)
    end

    it 'shows the design comment action in the activity page' do
      visit activity_project_path(project)

      expect(page).to have_content('joined project')
      expect(page).to have_content(design_activity(uploader, 'uploaded'))
      expect(page).to have_content(design_activity(editor, 'revised'))
      expect(page).to have_content(design_activity(deleter, 'deleted'))
    end

    it 'allows filtering out the design events', :aggregate_failures do
      visit activity_project_path(project, event_filter: EventFilter::ISSUE)

      expect(page).not_to have_content(design_activity(uploader, 'uploaded'))
      expect(page).not_to have_content(design_activity(editor, 'revised'))
      expect(page).not_to have_content(design_activity(deleter, 'deleted'))
    end

    it 'allows filtering in the design events', :aggregate_failures do
      visit activity_project_path(project, event_filter: EventFilter::DESIGNS)

      expect(page).not_to have_content('joined project')
      expect(page).to have_content(design_activity(uploader, 'uploaded'))
      expect(page).to have_content(design_activity(editor, 'revised'))
      expect(page).to have_content(design_activity(deleter, 'deleted'))
    end
  end

  context 'the project is public' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:user) { create(:user) }

    it_behaves_like 'being able to see design activity'
  end

  context 'the project is private' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, developer_projects: [project]) }

    it_behaves_like 'being able to see design activity'
  end
end
