# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project', :js do
  include Select2Helper
  include Spec::Support::Helpers::Features::TopNavSpecHelpers

  shared_examples 'combined_menu: feature flag examples' do
    context 'as a user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'shows a message if multiple levels are restricted' do
        Gitlab::CurrentSettings.update!(
          restricted_visibility_levels: [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL]
        )

        visit new_project_path
        find('[data-qa-panel-name="blank_project"]').click

        expect(page).to have_content 'Other visibility settings have been disabled by the administrator.'
      end

      it 'shows a message if all levels are restricted' do
        Gitlab::CurrentSettings.update!(
          restricted_visibility_levels: Gitlab::VisibilityLevel.values
        )

        visit new_project_path
        find('[data-qa-panel-name="blank_project"]').click

        expect(page).to have_content 'Visibility settings have been disabled by the administrator.'
      end
    end

    context 'as an admin' do
      let(:user) { create(:admin) }

      before do
        sign_in(user)
      end

      it 'shows "New project" page', :js do
        visit new_project_path
        find('[data-qa-panel-name="blank_project"]').click

        expect(page).to have_content('Project name')
        expect(page).to have_content('Project URL')
        expect(page).to have_content('Project slug')

        click_link('New project')
        find('[data-qa-panel-name="import_project"]').click

        expect(page).to have_link('GitHub')
        expect(page).to have_link('Bitbucket')
        expect(page).to have_link('GitLab.com')
        expect(page).to have_button('Repo by URL')
        expect(page).to have_link('GitLab export')
      end

      describe 'manifest import option' do
        before do
          visit new_project_path

          find('[data-qa-panel-name="import_project"]').click
        end

        it 'has Manifest file' do
          expect(page).to have_link('Manifest file')
        end
      end

      context 'Visibility level selector', :js do
        Gitlab::VisibilityLevel.options.each do |key, level|
          it "sets selector to #{key}" do
            stub_application_setting(default_project_visibility: level)

            visit new_project_path
            find('[data-qa-panel-name="blank_project"]').click
            page.within('#blank-project-pane') do
              expect(find_field("project_visibility_level_#{level}")).to be_checked
            end
          end

          it "saves visibility level #{level} on validation error" do
            visit new_project_path
            find('[data-qa-panel-name="blank_project"]').click

            choose(key)
            click_button('Create project')
            page.within('#blank-project-pane') do
              expect(find_field("project_visibility_level_#{level}")).to be_checked
            end
          end
        end

        context 'when group visibility is private but default is internal' do
          let_it_be(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

          before do
            stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it 'has private selected' do
              visit new_project_path(namespace_id: group.id)
              find('[data-qa-panel-name="blank_project"]').click

              page.within('#blank-project-pane') do
                expect(find_field("project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).to be_checked
              end
            end
          end

          context 'when admin mode is disabled' do
            it 'is not allowed' do
              visit new_project_path(namespace_id: group.id)

              expect(page).to have_content('Not Found')
            end
          end
        end

        context 'when group visibility is public but user requests private' do
          let_it_be(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

          before do
            stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it 'has private selected' do
              visit new_project_path(namespace_id: group.id, project: { visibility_level: Gitlab::VisibilityLevel::PRIVATE })
              find('[data-qa-panel-name="blank_project"]').click

              page.within('#blank-project-pane') do
                expect(find_field("project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).to be_checked
              end
            end
          end

          context 'when admin mode is disabled' do
            it 'is not allowed' do
              visit new_project_path(namespace_id: group.id, project: { visibility_level: Gitlab::VisibilityLevel::PRIVATE })

              expect(page).to have_content('Not Found')
            end
          end
        end
      end

      context 'Readme selector' do
        it 'shows the initialize with Readme checkbox on "Blank project" tab' do
          visit new_project_path
          find('[data-qa-panel-name="blank_project"]').click

          expect(page).to have_css('input#project_initialize_with_readme')
          expect(page).to have_content('Initialize repository with a README')
        end

        it 'does not show the initialize with Readme checkbox on "Create from template" tab' do
          visit new_project_path
          find('[data-qa-panel-name="create_from_template"]').click
          first('.choose-template').click

          page.within '.project-fields-form' do
            expect(page).not_to have_css('input#project_initialize_with_readme')
            expect(page).not_to have_content('Initialize repository with a README')
          end
        end

        it 'does not show the initialize with Readme checkbox on "Import project" tab' do
          visit new_project_path
          find('[data-qa-panel-name="import_project"]').click
          first('.js-import-git-toggle-button').click

          page.within '#import-project-pane' do
            expect(page).not_to have_css('input#project_initialize_with_readme')
            expect(page).not_to have_content('Initialize repository with a README')
          end
        end
      end

      context 'Namespace selector' do
        context 'with user namespace' do
          before do
            visit new_project_path
            find('[data-qa-panel-name="blank_project"]').click
          end

          it 'selects the user namespace' do
            page.within('#blank-project-pane') do
              expect(page).to have_select('project[namespace_id]', visible: false, selected: user.username)
            end
          end
        end

        context 'with group namespace' do
          let(:group) { create(:group, :private) }

          before do
            group.add_owner(user)
            visit new_project_path(namespace_id: group.id)
            find('[data-qa-panel-name="blank_project"]').click
          end

          it 'selects the group namespace' do
            page.within('#blank-project-pane') do
              expect(page).to have_select('project[namespace_id]', visible: false, selected: group.name)
            end
          end
        end

        context 'with subgroup namespace' do
          let(:group) { create(:group) }
          let(:subgroup) { create(:group, parent: group) }

          before do
            group.add_maintainer(user)
            visit new_project_path(namespace_id: subgroup.id)
            find('[data-qa-panel-name="blank_project"]').click
          end

          it 'selects the group namespace' do
            page.within('#blank-project-pane') do
              expect(page).to have_select('project[namespace_id]', visible: false, selected: subgroup.full_path)
            end
          end
        end

        context 'when changing namespaces dynamically', :js do
          let(:public_group) { create(:group, :public) }
          let(:internal_group) { create(:group, :internal) }
          let(:private_group) { create(:group, :private) }

          before do
            public_group.add_owner(user)
            internal_group.add_owner(user)
            private_group.add_owner(user)
            visit new_project_path(namespace_id: public_group.id)
            find('[data-qa-panel-name="blank_project"]').click
          end

          it 'enables the correct visibility options' do
            select2(user.namespace_id, from: '#project_namespace_id')
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).not_to be_disabled

            select2(public_group.id, from: '#project_namespace_id')
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).not_to be_disabled

            select2(internal_group.id, from: '#project_namespace_id')
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).to be_disabled

            select2(private_group.id, from: '#project_namespace_id')
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).to be_disabled
            expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).to be_disabled
          end
        end
      end

      context 'Import project options', :js do
        before do
          visit new_project_path
          find('[data-qa-panel-name="import_project"]').click
        end

        context 'from git repository url, "Repo by URL"' do
          before do
            first('.js-import-git-toggle-button').click
          end

          it 'does not autocomplete sensitive git repo URL' do
            autocomplete = find('#project_import_url')['autocomplete']

            expect(autocomplete).to eq('off')
          end

          it 'shows import instructions' do
            git_import_instructions = first('.js-toggle-content')

            expect(git_import_instructions).to be_visible
            expect(git_import_instructions).to have_content 'Git repository URL'
          end

          it 'keeps "Import project" tab open after form validation error' do
            collision_project = create(:project, name: 'test-name-collision', namespace: user.namespace)

            fill_in 'project_import_url', with: collision_project.http_url_to_repo
            fill_in 'project_name', with: collision_project.name

            click_on 'Create project'

            expect(page).to have_css('#import-project-pane.active')
            expect(page).not_to have_css('.toggle-import-form.hide')
          end
        end

        context 'from GitHub' do
          before do
            first('.js-import-github').click
          end

          it 'shows import instructions' do
            expect(page).to have_content('Authenticate with GitHub')
            expect(current_path).to eq new_import_github_path
          end
        end

        context 'from manifest file' do
          before do
            first('.import_manifest').click
          end

          it 'shows import instructions' do
            expect(page).to have_content('Manifest file import')
            expect(current_path).to eq new_import_manifest_path
          end
        end
      end

      context 'Namespace selector' do
        context 'with group with DEVELOPER_MAINTAINER_PROJECT_ACCESS project_creation_level' do
          let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

          before do
            group.add_developer(user)
            visit new_project_path(namespace_id: group.id)
            find('[data-qa-panel-name="blank_project"]').click
          end

          it 'selects the group namespace' do
            page.within('#blank-project-pane') do
              expect(page).to have_select('project[namespace_id]', visible: false, selected: group.full_path)
            end
          end
        end
      end
    end
  end

  context 'with combined_menu feature flag on' do
    let(:needs_rewrite_for_combined_menu_flag_on) { true }

    before do
      stub_feature_flags(combined_menu: true)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  context 'with combined_menu feature flag off' do
    let(:needs_rewrite_for_combined_menu_flag_on) { false }

    before do
      stub_feature_flags(combined_menu: false)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end
end
