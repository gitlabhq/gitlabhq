# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit group label' do
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
end
