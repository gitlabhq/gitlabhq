# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by draft', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    create(:merge_request, title: 'Draft: Bugfix', source_project: project, target_project: project, source_branch: 'bugfix2')

    sign_in(user)
    visit project_merge_requests_path(project)
  end

  it 'filters results' do
    select_tokens 'Draft', 'Yes', submit: true

    expect(page).to have_content('Draft: Bugfix')
  end
end
