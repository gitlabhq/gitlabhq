# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group labels', feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:label) { create(:label, project: project) }

  before_all do
    project.add_owner(user)
  end

  before do
    sign_in(user)
    visit project_labels_path(project)
  end

  it_behaves_like 'handles archived labels in view'
end
