# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit group label', feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:label) { create(:group_label, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)

    visit edit_group_label_path(group, label)
  end

  it 'update label with new title' do
    fill_in 'label_title', with: 'new label name'
    click_button 'Save changes'

    expect(page).to have_current_path(root_path, ignore_query: true)
    expect(label.reload.title).to eq('new label name')
  end

  it 'allows user to delete label', :js do
    click_button 'Delete'

    within_modal do
      expect(page).to have_content("#{label.title} will be permanently deleted from #{group.name}. This cannot be undone.")

      click_link 'Delete label'
    end

    expect(page).to have_content("#{label.title} was removed").and have_no_content("#{label.title}</span>")
  end

  describe 'lock_on_merge' do
    let(:label_unlocked) { create(:group_label, group: group, lock_on_merge: false) }
    let(:label_locked) { create(:group_label, group: group, lock_on_merge: true) }
    let(:edit_label_path_unlocked) { edit_group_label_path(group, label_unlocked) }
    let(:edit_label_path_locked) { edit_group_label_path(group, label_locked) }

    before do
      visit edit_label_path_unlocked
    end

    it_behaves_like 'lock_on_merge when editing labels'
  end
end
