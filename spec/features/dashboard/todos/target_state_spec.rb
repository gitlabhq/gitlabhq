# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard > Todo target states', feature_category: :team_planning do
  let_it_be(:user)    { create(:user) }
  let_it_be(:author)  { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  it 'on a closed issue todo has closed label' do
    issue_closed = create(:issue, state: 'closed', project: project)
    create_todo issue_closed
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).to have_content('Closed')
    end
  end

  it 'on an open issue todo does not have an open label' do
    issue_open = create(:issue, project: project)
    create_todo issue_open
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).not_to have_content('Open')
    end
  end

  it 'on a merged merge request todo has merged label' do
    mr_merged = create(:merge_request, :simple, :merged, author: user, source_project: project)
    create_todo mr_merged
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).to have_content('Merged')
    end
  end

  it 'on a closed merge request todo has closed label' do
    mr_closed = create(:merge_request, :simple, :closed, author: user, source_project: project)
    create_todo mr_closed
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).to have_content('Closed')
    end
  end

  it 'on an open merge request todo does not have an open label' do
    mr_open = create(:merge_request, :simple, author: user, source_project: project)
    create_todo mr_open
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).not_to have_content('Open')
    end
  end

  def create_todo(target)
    create(:todo, :mentioned, user: user, project: project, target: target, author: author)
  end
end
