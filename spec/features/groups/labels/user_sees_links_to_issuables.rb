require 'spec_helper'

feature 'Groups > Labels > User sees links to issuables' do
  set(:group) { create(:group, :public) }

  before do
    create(:group_label, group: group, title: 'bug')
    visit group_labels_path(group)
  end

  scenario 'shows links to MRs and issues' do
    expect(page).to have_link('view merge requests')
    expect(page).to have_link('view open issues')
  end
end
