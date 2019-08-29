# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard > Todo target states' do
  let(:user)    { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    sign_in(user)
  end

  it 'on a closed issue todo has closed label' do
    issue_closed = create(:issue, state: 'closed')
    create_todo issue_closed
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).to have_content('Closed')
    end
  end

  it 'on an open issue todo does not have an open label' do
    issue_open = create(:issue)
    create_todo issue_open
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).not_to have_content('Open')
    end
  end

  it 'on a merged merge request todo has merged label' do
    mr_merged = create(:merge_request, :simple, :merged, author: user)
    create_todo mr_merged
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).to have_content('Merged')
    end
  end

  it 'on a closed merge request todo has closed label' do
    mr_closed = create(:merge_request, :simple, :closed, author: user)
    create_todo mr_closed
    visit dashboard_todos_path

    page.within '.todos-list' do
      expect(page).to have_content('Closed')
    end
  end

  it 'on an open merge request todo does not have an open label' do
    mr_open = create(:merge_request, :simple, author: user)
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
