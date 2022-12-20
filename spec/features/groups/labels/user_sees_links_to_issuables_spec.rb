# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Labels > User sees links to issuables', feature_category: :team_planning do
  let_it_be(:group) { create(:group, :public) }

  before do
    create(:group_label, group: group, title: 'bug')
    visit group_labels_path(group)
  end

  it 'shows links to MRs and issues' do
    page.within('.labels-container') do
      expect(page).to have_link('Merge requests')
      expect(page).to have_link('Issues')
    end
  end
end
