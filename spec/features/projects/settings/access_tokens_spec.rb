# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Access Tokens', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:bot_user) { create(:user, :project_bot) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:resource_settings_access_tokens_path) { project_settings_access_tokens_path(project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    stub_feature_flags(bootstrap_confirmation_modals: false)
    sign_in(user)
  end

  def create_resource_access_token
    project.add_maintainer(bot_user)

    create(:personal_access_token, user: bot_user)
  end

  context 'when user is not a project maintainer' do
    before do
      project.add_developer(user)
    end

    it_behaves_like 'resource access tokens missing access rights'
  end

  describe 'token creation' do
    it_behaves_like 'resource access tokens creation', 'project'

    context 'when token creation is not allowed' do
      it_behaves_like 'resource access tokens creation disallowed', 'Project access token creation is disabled in this group. You can still use and manage existing tokens.'

      context 'with a project in a personal namespace' do
        let(:personal_project) { create(:project) }

        before do
          personal_project.add_maintainer(user)
        end

        it 'shows access token creation form and text' do
          visit project_settings_access_tokens_path(personal_project)

          expect(page).to have_selector('#new_resource_access_token')
          expect(page).to have_text('Generate project access tokens scoped to this project for your applications that need access to the GitLab API.')
        end
      end
    end
  end

  describe 'active tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'active resource access tokens'
  end

  describe 'inactive tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'inactive resource access tokens', 'This project has no active access tokens.'
  end
end
