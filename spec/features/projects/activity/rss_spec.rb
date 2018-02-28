require 'spec_helper'

feature 'Project Activity RSS' do
  let(:user) { create(:user) }
  let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:path) { activity_project_path(project) }

  before do
    create(:issue, project: project)
  end

  context 'when signed in' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's RSS token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without an RSS token"
  end
end
