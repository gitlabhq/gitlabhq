# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Activity RSS', feature_category: :groups_and_projects do
  let(:project) { create(:project, :public) }
  let(:user) { project.first_owner }
  let(:path) { activity_project_path(project) }

  before do
    create(:issue, project: project)
  end

  context 'when signed in' do
    before do
      sign_in(project.first_owner)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's feed token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without a feed token"
  end
end
