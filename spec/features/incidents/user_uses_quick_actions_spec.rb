# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incidents > User uses quick actions', :js, feature_category: :incident_management do
  include Features::NotesHelpers

  describe 'incident-only commands' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:issue, reload: true) { create(:incident, project: project) }

    before do
      project.add_developer(user)
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    after do
      wait_for_requests
    end

    it_behaves_like 'timeline quick action'
  end
end
