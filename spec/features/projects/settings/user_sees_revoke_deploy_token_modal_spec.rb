# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Repository Settings > User sees revoke deploy token modal', :js, feature_category: :continuous_delivery do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:role) { :developer }
  let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, projects: [project]) }

  before do
    project.add_role(user, role)
    sign_in(user)
    visit(project_settings_repository_path(project))
    click_button('Revoke')
  end

  it 'shows the revoke deploy token modal' do
    expect(page).to have_content('You are about to revoke')
  end
end
