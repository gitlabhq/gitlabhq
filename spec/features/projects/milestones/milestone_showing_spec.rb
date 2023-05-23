# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project milestone', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  let(:milestone) { create(:milestone, project: project) }

  before do
    sign_in(user)
  end

  it_behaves_like 'milestone with interactive markdown task list items in description' do
    let(:milestone_path) { project_milestone_path(project, milestone) }
  end
end
