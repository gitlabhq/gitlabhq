# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Repository > Branch rules settings', feature_category: :groups_and_projects do
  let(:project) { create(:project_empty_repo) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  subject(:request) { visit project_settings_repository_branch_rules_path(project) }

  before do
    project.add_role(user, role)
    sign_in(user)
  end

  context 'for developer' do
    let(:role) { :developer }

    it 'is not allowed to view' do
      request

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'for maintainer' do
    let(:role) { :maintainer }

    context 'Branch rules', :js do
      it 'renders breadcrumbs' do
        request

        page.within '.breadcrumbs' do
          expect(page).to have_link('Repository Settings', href: project_settings_repository_path(project))
          expect(page).to have_link('Branch rules',
            href: project_settings_repository_path(project, anchor: 'branch-rules'))
          expect(page).to have_link('Details', href: '#')
        end
      end

      it 'renders branch rules page' do
        request

        expect(page).to have_content('Branch rules')
      end
    end
  end
end
