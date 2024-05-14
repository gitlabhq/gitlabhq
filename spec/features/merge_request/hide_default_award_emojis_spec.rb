# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User does not see default award emoji', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository, show_default_award_emojis: false) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, author: user) }

  before do
    sign_in(user)

    visit project_merge_request_path(project, merge_request)
    wait_for_requests
  end

  it { expect(page).not_to have_selector('[data-testid="award-button"]') }
end
