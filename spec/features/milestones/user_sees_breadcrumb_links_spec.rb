# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project milestone breadcrumb', :js, feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:milestone) { create(:milestone, project: project) }
  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(new_project_milestone_path(project))
  end

  it 'displays link to project milestones and new project   milestone' do
    within_testid 'breadcrumb-links' do
      expect(find_link('Milestones')[:href]).to end_with(project_milestones_path(project))
      expect(find_link('New')[:href]).to end_with(new_project_milestone_path(project))
    end
  end
end
