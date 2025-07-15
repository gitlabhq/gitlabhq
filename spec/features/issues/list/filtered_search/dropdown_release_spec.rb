# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown release', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:release) { create(:release, tag: 'v1.0', project: project) }
  let_it_be(:crazy_release) { create(:release, tag: '☺!/"#%&\'{}+,-.<>;=@]_`{|}🚀', project: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)

    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the releases when opened' do
      select_tokens 'Release', '='

      # Expect None, Any, v1.0, !/\"#%&'{}+,-.<>;=@]_`{|}
      expect_suggestion_count 4
    end
  end
end
