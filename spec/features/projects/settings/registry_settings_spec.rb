# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Packages and registries',
  feature_category: :container_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { ProjectFeature::ENABLED }

  let(:help_page_href) { help_page_path('administration/packages/container_registry_metadata_database.md') }

  before do
    project.project_feature.update!(container_registry_access_level: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    sign_in(user)
    stub_container_registry_config(enabled: container_registry_enabled)
    allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
  end

  describe 'layout', :js do
    it 'renders sections' do
      visit_page

      expect(page).to have_selector 'h1.gl-sr-only', text: 'Packages and registries settings'
      expect(page).to have_selector 'h2', text: 'Package registry'
      expect(page).to have_selector 'h2', text: 'Container registry'
    end

    it 'shows active tab on sidebar' do
      visit_page

      within_testid('super-sidebar') do
        expect(page).to have_selector('button[aria-expanded="true"]', text: 'Settings')
        expect(page).to have_selector('[aria-current="page"]', text: 'Packages and registries')
      end
    end

    it 'passes axe automated accessibility testing' do
      visit_page

      click_button 'Expand Package registry'

      click_button 'Expand Container registry'

      wait_for_requests

      expect(page).to be_axe_clean.within('[data-testid="packages-and-registries-project-settings"]') # rubocop:todo Capybara/TestidFinders -- Doesn't cover use case, see https://gitlab.com/gitlab-org/gitlab/-/issues/442224
                                  .skipping :'link-in-text-block'
    end
  end

  shared_examples 'package registry settings' do
    describe 'package protection rules' do
      let(:settings_block_id) { 'project-packages-protection-rules-settings' }
      let(:access_level_dropdown) { 'Minimum access level for push' }

      it 'shows available section' do
        visit_method

        settings_block = find_by_testid(settings_block_id)
        expect(settings_block).to have_text 'Protected packages'
      end

      describe 'rule management' do
        context 'when creating a new rule' do
          it 'successfully creates a protection rule' do
            visit_method

            within_testid settings_block_id do
              click_button 'Add protection rule'

              fill_in 'Name pattern', with: '*test*'
              select 'Npm', from: 'Type'
              select 'Owner', from: access_level_dropdown

              click_button 'Add rule'
            end

            within_testid settings_block_id do
              expect(page).not_to have_button 'Add rule'
              expect(page).to have_content('*test*')
              expect(page).to have_content('npm')
              expect(page).to have_select(access_level_dropdown, selected: 'Owner')
            end
          end
        end

        context 'with existing protection rule' do
          let_it_be(:package_protection_rule) do
            create(:package_protection_rule, project: project)
          end

          before do
            visit_method
          end

          it 'displays the existing rule correctly' do
            within_testid settings_block_id do
              expect(page).to have_content(package_protection_rule.package_name_pattern)
              expect(page).to have_content(package_protection_rule.package_type)
              expect(page).to have_select(access_level_dropdown, selected: 'Maintainer')
            end
          end

          it 'allows editing the rule' do
            within_testid settings_block_id do
              select 'Admin', from: access_level_dropdown
            end

            expect(page).to have_content('Package protection rule updated.')
          end

          it 'allows deleting the rule' do
            within_testid settings_block_id do
              click_button 'Delete'
            end

            click_button 'Delete package protection rule'

            expect(page).to have_content('Package protection rule deleted.')

            within_testid settings_block_id do
              expect(page).not_to have_content(package_protection_rule.package_name_pattern)
            end
          end
        end
      end
    end
  end

  shared_examples 'container registry settings' do
    describe 'Container repository protection rules' do
      let(:settings_block_id) { 'project-container-repository-protection-rules-settings' }

      it 'shows available section' do
        visit_method

        settings_block = find_by_testid(settings_block_id)
        expect(settings_block).to have_text 'Protected container repositories'
      end

      describe 'creating a rule' do
        it 'creates a rule' do
          visit_method

          within_testid settings_block_id do
            click_button 'Add protection rule'
            fill_in 'Repository path pattern', with: "#{project.full_path}/*test*"
            select 'Owner', from: 'Minimum access level for push'
            click_button 'Add rule'
          end

          settings_block = find_by_testid(settings_block_id)
          expect(settings_block).not_to have_button 'Add rule'
          expect(settings_block).to have_content("#{project.full_path}/*test*")
          expect(settings_block).to have_select('Minimum access level for push', selected: 'Owner')
        end
      end

      context 'with protection rule' do
        let_it_be(:container_repository_protection_rule) do
          create(:container_registry_protection_rule, project: project)
        end

        it 'renders the rule' do
          visit_method

          settings_block = find_by_testid(settings_block_id)
          expect(settings_block).to have_content(container_repository_protection_rule.repository_path_pattern)
          expect(settings_block).to have_select('Minimum access level for push', selected: 'Maintainer')
        end

        it 'edits rule' do
          visit_method

          within_testid settings_block_id do
            select 'Admin', from: 'Minimum access level for push'
          end

          expect(page).to have_content('Container protection rule updated.')
        end

        it 'deletes rule' do
          visit_method

          within_testid settings_block_id do
            click_button 'Delete'
          end

          click_button 'Delete container protection rule'

          expect(page).to have_content('Container protection rule deleted.')
          settings_block = find_by_testid(settings_block_id)
          expect(settings_block).not_to have_content(container_repository_protection_rule.repository_path_pattern)
        end
      end
    end

    describe 'Container protection tag rules' do
      let(:settings_block_id) { 'project-container-protection-tag-rules-settings' }

      it 'shows available section' do
        visit_method

        settings_block = find_by_testid(settings_block_id)
        expect(settings_block).to have_text 'Protected container image tags'
      end

      describe 'creating a rule' do
        it 'creates a rule' do
          visit_method

          within_testid settings_block_id do
            click_button 'Add protection rule'
          end

          expect(page).to have_selector 'h2', text: 'Add protection rule'
          fill_in 'Protect container tags matching', with: 'v.*'
          select 'Owner', from: 'Minimum role allowed to push'
          select 'Admin', from: 'Minimum role allowed to delete'
          click_button 'Add rule'

          settings_block = find_by_testid(settings_block_id)
          expect(page).not_to have_selector 'h2', text: 'Add protection rule'
          expect(page).to have_content('Container protection rule created.')
          expect(settings_block).to have_content('v.*')
          expect(settings_block).to have_content('Owner')
          expect(settings_block).to have_content('Administrator')
        end
      end

      context 'with protection rule' do
        let_it_be(:container_protection_tag_rule) do
          create(:container_registry_protection_tag_rule,
            project: project,
            minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
            minimum_access_level_for_delete: Gitlab::Access::OWNER
          )
        end

        it 'renders the rule' do
          visit_method

          settings_block = find_by_testid(settings_block_id)
          expect(settings_block).to have_content(container_protection_tag_rule.tag_name_pattern)
          expect(settings_block).to have_content('Maintainer')
          expect(settings_block).to have_content('Owner')
        end

        it 'updates a rule' do
          visit_method

          within_testid settings_block_id do
            click_button 'Edit'
          end

          expect(page).to have_selector 'h2', text: 'Edit protection rule'
          fill_in 'Protect container tags matching', with: 'v1.*'
          select 'Maintainer', from: 'Minimum role allowed to push'
          select 'Maintainer', from: 'Minimum role allowed to delete'
          click_button 'Save changes'

          settings_block = find_by_testid(settings_block_id)
          expect(page).not_to have_selector 'h2', text: 'Edit protection rule'
          expect(page).to have_content('Container protection rule updated.')
          expect(settings_block).to have_content('v1.*')
          expect(find_by_testid('minimum-access-level-push-value')).to have_content('Maintainer')
          expect(find_by_testid('minimum-access-level-delete-value')).to have_content('Maintainer')
        end

        it 'deletes rule' do
          visit_method

          within_testid settings_block_id do
            click_button 'Delete'
          end

          click_button 'Delete rule'

          expect(page).to have_content('Container protection rule deleted.')
          settings_block = find_by_testid(settings_block_id)
          expect(settings_block).not_to have_content(container_protection_tag_rule.tag_name_pattern)
        end
      end
    end

    describe 'Cleanup policies' do
      let(:settings_block_id) { 'container-expiration-policy-project-settings' }

      it 'shows available section' do
        visit_method

        settings_block = find_by_testid(settings_block_id)
        expect(settings_block).to have_text 'Container registry cleanup policies'
      end

      it 'contains link to cleanup policies page' do
        visit_method

        expect(page).to have_link('Edit cleanup rules', href: cleanup_image_tags_project_settings_packages_and_registries_path(project))
      end

      context 'with a project without expiration policy' do
        before do
          project.container_expiration_policy.destroy!
        end

        context 'with container_expiration_policies_enable_historic_entries enabled' do
          before do
            stub_application_setting(container_expiration_policies_enable_historic_entries: true)
          end

          it 'displays the related section' do
            visit_method

            within_testid settings_block_id do
              expect(page).to have_link('Set cleanup rules', href: cleanup_image_tags_project_settings_packages_and_registries_path(project))
            end
          end
        end

        context 'with container_expiration_policies_enable_historic_entries disabled' do
          before do
            stub_application_setting(container_expiration_policies_enable_historic_entries: false)
          end

          it 'does not display the related section' do
            visit_method

            within_testid settings_block_id do
              expect(find('.gl-alert-title')).to have_content('Cleanup policy for tags is disabled')
            end
          end
        end
      end
    end

    it 'has link to next generation container registry docs' do
      allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)

      visit_method

      expect(page).to have_link('next-generation container registry', href: help_page_href)
    end
  end

  describe 'Package registry section', :js do
    it_behaves_like 'package registry settings' do
      let(:visit_method) { visit_and_expand_package_registry_section }
    end
  end

  describe 'Container registry section', :js do
    it_behaves_like 'container registry settings' do
      let(:visit_method) { visit_and_expand_container_registry_section }
    end
  end

  context 'when registry is disabled' do
    let(:container_registry_enabled) { false }

    it 'does not exists' do
      visit_page

      expect(page).not_to have_selector('[data-testid="container-expiration-policy-project-settings"]')
    end
  end

  context 'when container registry is disabled on project' do
    let(:container_registry_enabled_on_project) { ProjectFeature::DISABLED }

    it 'does not exists' do
      visit_page

      expect(page).not_to have_selector('[data-testid="container-expiration-policy-project-settings"]')
    end
  end

  private

  def visit_page
    visit project_settings_packages_and_registries_path(project)
  end

  def visit_and_expand_container_registry_section
    visit_page

    click_button 'Expand Container registry'
  end

  def visit_and_expand_package_registry_section
    visit_page

    click_button 'Expand Package registry'
  end
end
