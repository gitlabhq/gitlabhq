# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group labels', feature_category: :team_planning do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let!(:label) { create(:group_label, group: group) }
  let!(:label2) { create(:group_label) }

  before do
    group.add_owner(user)
    sign_in(user)
    visit group_labels_path(group)
  end

  it 'shows labels that belong to the group' do
    expect(page).to have_content(label.name)
    expect(page).not_to have_content(label2.name)
  end

  it 'shows a new label button' do
    expect(page).to have_link('New label')
  end

  it 'shows an edit label button', :js do
    page.within "#group_label_#{label.id}" do
      find_by_testid('label-actions-dropdown-toggle').click

      expect(page).to have_link('Edit')
    end
  end
end
