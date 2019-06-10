# frozen_string_literal: true

require 'spec_helper'

describe 'User promotes label' do
  set(:group) { create(:group) }
  set(:user) { create(:user) }
  set(:project) { create(:project, namespace: group) }
  set(:label) { create(:label, project: project) }

  context 'when user can admin group labels' do
    before do
      group.add_developer(user)
      sign_in(user)
      visit(project_labels_path(project))
    end

    it "shows label promote button" do
      expect(page).to have_selector('.js-promote-project-label-button')
    end
  end

  context 'when user cannot admin group labels' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit(project_labels_path(project))
    end

    it "does not show label promote button" do
      expect(page).not_to have_selector('.js-promote-project-label-button')
    end
  end
end
