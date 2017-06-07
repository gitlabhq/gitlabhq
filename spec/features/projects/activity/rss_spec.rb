require 'spec_helper'

feature 'Project Activity RSS' do
  let(:project) { create(:empty_project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:path) { activity_namespace_project_path(project.namespace, project) }

  before do
    create(:issue, project: project)
  end

  context 'when signed in' do
    before do
      user = create(:user)
      project.team << [user, :developer]
      login_as(user)
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
