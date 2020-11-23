# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User follows pipeline suggest nudge spec when feature is enabled', :js do
  include CookieHelper

  let(:project) { create(:project, :empty_repo) }
  let(:user) { project.owner }

  describe 'viewing the new blob page' do
    before do
      sign_in(user)
    end

    context 'when the page is loaded from the link using the suggest_gitlab_ci_yml param' do
      before do
        visit namespace_project_new_blob_path(namespace_id: project.namespace, project_id: project, id: 'master', suggest_gitlab_ci_yml: 'true')
      end

      it 'pre-fills .gitlab-ci.yml for file name' do
        file_name = page.find_by_id('file_name')

        expect(file_name.value).to have_content('.gitlab-ci.yml')
      end

      it 'chooses the .gitlab-ci.yml Template Type' do
        template_type = page.find(:css, '.template-type-selector .dropdown-toggle-text')

        expect(template_type.text).to have_content('.gitlab-ci.yml')
      end

      it 'displays suggest_gitlab_ci_yml popover' do
        page.find(:css, '.gitlab-ci-yml-selector').click

        popover_selector = '.suggest-gitlab-ci-yml'

        expect(page).to have_css(popover_selector, visible: true)

        page.within(popover_selector) do
          expect(page).to have_content('1/2: Choose a template')
        end
      end

      it 'sets the commit cookie when the Commit button is clicked' do
        click_button 'Commit changes'

        expect(get_cookie("suggest_gitlab_ci_yml_commit_#{project.id}")).to be_present
      end
    end

    context 'when the page is visited without the param' do
      before do
        visit namespace_project_new_blob_path(namespace_id: project.namespace, project_id: project, id: 'master')
      end

      it 'does not pre-fill .gitlab-ci.yml for file name' do
        file_name = page.find_by_id('file_name')

        expect(file_name.value).not_to have_content('.gitlab-ci.yml')
      end

      it 'does not choose the .gitlab-ci.yml Template Type' do
        template_type = page.find(:css, '.template-type-selector .dropdown-toggle-text')

        expect(template_type.text).to have_content('Select a template type')
      end

      it 'does not display suggest_gitlab_ci_yml popover' do
        popover_selector = '.b-popover.suggest-gitlab-ci-yml'

        expect(page).not_to have_css(popover_selector, visible: true)
      end
    end
  end
end
