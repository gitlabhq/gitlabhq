# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User edits labels", feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(edit_project_label_path(project, label))
  end

  it "updates label's title" do
    new_title = "fix"

    fill_in("Title", with: new_title)
    click_button("Save changes")

    page.within(".other-labels .manage-labels-list") do
      expect(page).to have_content(new_title).and have_no_content(label.title)
    end
  end

  it 'allows user to delete label', :js do
    click_button 'Delete'

    within_modal do
      expect(page).to have_content("#{label.title} will be permanently deleted from #{project.name}. This cannot be undone.")

      click_link 'Delete label'
    end

    expect(page).to have_content('Label was removed')
  end
end
