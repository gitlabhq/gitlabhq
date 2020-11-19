# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by draft', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    create(:merge_request, title: 'Draft: Bugfix', source_project: project, target_project: project, source_branch: 'bugfix2')

    sign_in(user)
    visit project_merge_requests_path(project)
  end

  it 'filters results' do
    input_filtered_search_keys('draft:=yes')

    expect(page).to have_content('Draft: Bugfix')
  end

  it 'does not allow filtering by is not equal' do
    find('#filtered-search-merge_requests').click

    click_button 'Draft'

    expect(page).not_to have_content('!=')
  end
end
