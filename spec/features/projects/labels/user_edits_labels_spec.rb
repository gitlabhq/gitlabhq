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

    visit edit_project_label_path(project, label)
  end

  it 'update label with new title' do
    new_title = 'fix'

    fill_in('Title', with: new_title)
    click_button('Save changes')

    page.within('.other-labels .manage-labels-list') do
      expect(page).to have_content(new_title).and have_no_content(label.title)
    end
  end

  it 'allows user to delete label', :js do
    click_button 'Delete'

    within_modal do
      expect(page).to have_content("#{label.title} will be permanently deleted from #{project.name}. This cannot be undone.")

      click_link 'Delete label'
    end

    expect(page).to have_content("#{label.title} was removed").and have_no_content("#{label.title}</span>")
  end

  describe 'lock_on_merge' do
    let_it_be_with_reload(:label_unlocked) { create(:label, project: project, lock_on_merge: false) }
    let_it_be(:label_locked) { create(:label, project: project, lock_on_merge: true) }
    let_it_be(:edit_label_path_unlocked) { edit_project_label_path(project, label_unlocked) }
    let_it_be(:edit_label_path_locked) { edit_project_label_path(project, label_locked) }

    before do
      visit edit_label_path_unlocked
    end

    it_behaves_like 'lock_on_merge when editing labels'
  end
end
