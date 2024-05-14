# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User promotes label', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:label) { create(:label, project: project) }

  context 'when user can admin group labels' do
    before do
      group.add_developer(user)
      sign_in(user)
      visit(project_labels_path(project))
    end

    it "shows label promote button" do
      page.within "#project_label_#{label.id}" do
        find_by_testid('label-actions-dropdown-toggle').click

        expect(page).to have_button('Promote to group label')
      end
    end
  end

  context 'when user cannot admin group labels' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit(project_labels_path(project))
    end

    it "does not show label promote button" do
      page.within "#project_label_#{label.id}" do
        find_by_testid('label-actions-dropdown-toggle').click

        expect(page).not_to have_button('Promote to group label')
      end
    end
  end
end
