require 'spec_helper'

describe 'Group labels' do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let!(:label) { create(:group_label, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
    visit group_labels_path(group)
  end

  it 'label has edit button', :js do
    expect(page).to have_selector('.label-action.edit')
  end
end
