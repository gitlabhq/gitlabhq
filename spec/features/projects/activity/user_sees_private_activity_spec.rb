# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Activity > User sees private activity', :js, feature_category: :groups_and_projects do
  let(:project) { create(:project, :public) }
  let(:author) { create(:user) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, :confidential, project: project, author: author) }
  let(:message) { "#{author.name} #{author.to_reference} opened issue #{issue.to_reference}" }

  before do
    project.add_developer(author)

    create(:event, :created, project: project, target: issue, author: author)
  end

  it 'shows the activity to a logged-in user with permissions' do
    sign_in(author)
    visit activity_project_path(project)

    expect(page).to have_content(message)
  end

  it 'hides the activity from a logged-in user without permissions' do
    sign_in(user)
    visit activity_project_path(project)

    expect(page).not_to have_content(message)
  end

  it 'hides the activity from an anonymous user' do
    visit activity_project_path(project)

    expect(page).not_to have_content(message)
  end
end
