# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown label', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:label) { create(:label, project: project, title: 'bug-label') }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the labels when opened' do
      select_tokens 'Label', '='

      # Expect None, Any, bug-label
      expect_suggestion_count 3
    end
  end
end
