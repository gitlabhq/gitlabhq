# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown base', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      select_tokens 'Assignee', '='
      initial_size = get_suggestion_count

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.add_maintainer(new_user)
      click_button 'Clear'
      select_tokens 'Assignee', '='

      expect_suggestion_count(initial_size)
    end
  end
end
