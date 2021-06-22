# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > CI/CD > Container registry tag expiration policy', :js do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { true }

  subject { visit project_settings_packages_and_registries_path(project) }

  before do
    project.update!(container_registry_enabled: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    sign_in(user)
    stub_container_registry_config(enabled: container_registry_enabled)
  end

  context 'as owner' do
    it 'shows available section' do
      subject

      settings_block = find('[data-testid="registry-settings-app"]')
      expect(settings_block).to have_text 'Clean up image tags'
    end

    it 'saves cleanup policy submit the form' do
      subject

      within '[data-testid="registry-settings-app"]' do
        select('Every day', from: 'Run cleanup')
        select('50 tags per image name', from: 'Keep the most recent:')
        fill_in('Keep tags matching:', with: 'stable')
        select('7 days', from: 'Remove tags older than:')
        fill_in('Remove tags matching:', with: '.*-production')

        submit_button = find('[data-testid="save-button"')
        expect(submit_button).not_to be_disabled
        submit_button.click
      end

      expect(find('.gl-toast')).to have_content('Cleanup policy successfully saved.')
    end

    it 'does not save cleanup policy submit form with invalid regex' do
      subject

      within '[data-testid="registry-settings-app"]' do
        fill_in('Remove tags matching:', with: '*-production')

        submit_button = find('[data-testid="save-button"')
        expect(submit_button).not_to be_disabled
        submit_button.click
      end

      expect(find('.gl-toast')).to have_content('Something went wrong while updating the cleanup policy.')
    end
  end

  context 'with a project without expiration policy' do
    where(:application_setting, :feature_flag, :result) do
      true  | true  | :available_section
      true  | false | :available_section
      false | true  | :available_section
      false | false | :disabled_message
    end

    with_them do
      before do
        project.container_expiration_policy.destroy!
        stub_feature_flags(container_expiration_policies_historic_entry: false)
        stub_application_setting(container_expiration_policies_enable_historic_entries: application_setting)
        stub_feature_flags(container_expiration_policies_historic_entry: project) if feature_flag
      end

      it 'displays the expected result' do
        subject

        within '[data-testid="registry-settings-app"]' do
          case result
          when :available_section
            expect(find('[data-testid="enable-toggle"]')).to have_content('Disabled - Tags will not be automatically deleted.')
          when :disabled_message
            expect(find('.gl-alert-title')).to have_content('Cleanup policy for tags is disabled')
          end
        end
      end
    end
  end

  context 'when registry is disabled' do
    let(:container_registry_enabled) { false }

    it 'does not exists' do
      subject

      expect(page).not_to have_selector('[data-testid="registry-settings-app"]')
    end
  end

  context 'when container registry is disabled on project' do
    let(:container_registry_enabled_on_project) { false }

    it 'does not exists' do
      subject

      expect(page).not_to have_selector('[data-testid="registry-settings-app"]')
    end
  end
end
