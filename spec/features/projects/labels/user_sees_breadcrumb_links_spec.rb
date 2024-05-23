# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project label breadcrumb', :js, feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(project_labels_path(project))
  end

  it 'displays link to project labels and new project label' do
    within_testid 'breadcrumb-links' do
      expect(find_link('Labels')[:href]).to end_with(project_labels_path(project))
    end
  end
end
