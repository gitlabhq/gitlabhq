# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User does not see default award emoji', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository, show_default_award_emojis: false) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, author: user) }

  before do
    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it 'does not show the default award emoji' do
    expect(page).to have_testid('emoji-picker')
    expect(page).not_to have_testid('award-button')
  end
end
