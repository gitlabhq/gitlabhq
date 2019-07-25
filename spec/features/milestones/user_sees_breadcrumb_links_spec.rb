# frozen_string_literal: true

require 'rails_helper'

describe 'New project milestone breadcrumb' do
  let(:project) { create(:project) }
  let(:milestone) { create(:milestone, project: project) }
  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(new_project_milestone_path(project))
  end

  it 'displays link to project milestones and new project   milestone' do
    page.within '.breadcrumbs' do
      expect(find_link('Milestones')[:href]).to end_with(project_milestones_path(project))
      expect(find_link('New')[:href]).to end_with(new_project_milestone_path(project))
    end
  end
end
