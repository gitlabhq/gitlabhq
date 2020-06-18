# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a group label' do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
    visit group_labels_path(group)
  end

  it 'creates a new label' do
    click_link 'New label'
    fill_in 'Title', with: 'test-label'
    click_button 'Create label'

    expect(page).to have_content 'test-label'
    expect(current_path).to eq(group_labels_path(group))
  end
end
