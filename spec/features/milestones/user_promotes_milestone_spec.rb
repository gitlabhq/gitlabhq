# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User promotes milestone' do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  context 'when user can admin group milestones' do
    before do
      group.add_developer(user)
      sign_in(user)
      visit(project_milestones_path(project))
    end

    it "shows milestone promote button" do
      expect(page).to have_selector('.js-promote-project-milestone-button')
    end
  end

  context 'when user cannot admin group milestones' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit(project_milestones_path(project))
    end

    it "does not show milestone promote button" do
      expect(page).not_to have_selector('.js-promote-project-milestone-button')
    end
  end
end
