# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Milestone editing", :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: 'test', namespace: user.namespace) }

  let(:milestone) { create(:milestone, project: project, start_date: Date.today, due_date: 5.days.from_now) }

  before do
    sign_in(user)

    visit(edit_project_milestone_path(project, milestone))
  end

  it_behaves_like 'milestone handling version conflicts'
end
