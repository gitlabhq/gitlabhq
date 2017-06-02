require 'spec_helper'

feature 'Project RSS' do
  let(:project) { create(:project, :repository, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:path) { namespace_project_path(project.namespace, project) }

  context 'when signed in' do
    before do
      user = create(:user)
      project.team << [user, :developer]
      login_as(user)
      visit path
    end

    it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "an autodiscoverable RSS feed without an RSS token"
  end
end
