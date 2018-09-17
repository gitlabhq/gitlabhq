# frozen_string_literal: true

require 'spec_helper'

describe 'Protected Environments' do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:environments) { %w(production development staging test) }

  before do
    stub_licensed_features(protected_environments: true)

    environments.each do |environment_name|
      create(:environment, name: environment_name, project: project)
    end

    create(:protected_environment, project: project, name: 'production')

    sign_in(user)
  end

  context 'logged in as developer' do
    before do
      project.add_developer(user)

      visit project_settings_ci_cd_path(project)
    end

    it 'does not have access to Protected Environments settings' do
      expect(page).to have_gitlab_http_status(404)
    end
  end

  context 'logged in as a maintainer' do
    before do
      project.add_maintainer(user)

      visit project_settings_ci_cd_path(project)
    end

    it 'has access to Protected Environments settings' do
      expect(page).to have_gitlab_http_status(200)
    end

    it 'allows seeing a list of protected environments' do
      within('.protected-environments-list') do
        expect(page).to have_content('production')
      end
    end

    it 'allows creating explicit protected environments', :js do
      set_protected_environment('staging')

      within('.js-new-protected-environment') do
        set_allowed_to_deploy('Developers + Maintainers')
        click_on('Protect')
      end

      wait_for_requests

      within('.protected-environments-list') do
        expect(page).to have_content('staging')
      end
    end

    it 'allows updating access to a protected environment', :js do
      within('.protected-environments-list') do
        set_allowed_to_deploy('Developers + Maintainers')
      end

      visit project_settings_ci_cd_path(project)

      within('.protected-environments-list') do
        expect(page).to have_content('1 role, 1 user')
      end
    end

    it 'allows unprotecting an environment', :js do
      within('.protected-environments-list') do
        accept_alert { click_on('Unprotect') }
      end

      wait_for_requests

      within('.protected-environments-list') do
        expect(page).not_to have_content('production')
      end
    end
  end

  def set_protected_environment(environment_name)
    within('.js-new-protected-environment') do
      find('.js-protected-environment-select').click
      find('.dropdown-input-field').set(environment_name)
      find('.is-focused').click
    end
  end

  def set_allowed_to_deploy(option)
    find('.js-allowed-to-deploy').click

    within('.dropdown-content') do
      Array(option).each { |opt| click_on(opt) }
    end

    find('.js-allowed-to-deploy').click
  end
end
