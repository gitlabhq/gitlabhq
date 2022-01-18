# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit group label' do
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

    expect(current_path).to eq(root_path)
    expect(label.reload.title).to eq('new label name')
  end

  it 'allows user to delete label', :js do
    click_button 'Delete'

    within_modal do
      expect(page).to have_content("#{label.title} will be permanently deleted from #{group.name}. This cannot be undone.")

      click_link 'Delete label'
    end

    expect(page).to have_content("#{label.title} deleted permanently")
  end
end
