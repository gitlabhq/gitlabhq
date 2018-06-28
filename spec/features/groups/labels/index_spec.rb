require 'spec_helper'

feature 'Group labels' do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let!(:label) { create(:group_label, group: group) }

  background do
    group.add_owner(user)
    sign_in(user)
    visit group_labels_path(group)
  end

  scenario 'label has edit button', :js do
    expect(page).to have_selector('.label-action.edit')
  end
end
