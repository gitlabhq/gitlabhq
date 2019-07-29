# frozen_string_literal: true

require 'rails_helper'

describe 'New issue breadcrumb' do
  let(:project) { create(:project) }
  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(new_project_issue_path(project))
  end

  it 'displays link to project issues and new issue' do
    page.within '.breadcrumbs' do
      expect(find_link('Issues')[:href]).to end_with(project_issues_path(project))
      expect(find_link('New')[:href]).to end_with(new_project_issue_path(project))
    end
  end
end
