# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees setup shortcut buttons', feature_category: :groups_and_projects do
  # For "New file", "Add license" functionality,
  # see spec/features/projects/files/project_owner_creates_license_file_spec.rb
  # see spec/features/projects/files/project_owner_sees_link_to_create_license_file_in_empty_project_spec.rb

  include FakeBlobHelpers

  let(:user) { create(:user) }

  describe 'empty project' do
    let(:project) { create(:project, :public, :empty_repo) }
    let(:presenter) { project.present(current_user: user) }

    describe 'as a normal user' do
      before do
        sign_in(user)
        visit project_path(project)
      end

      it 'project buttons are not visible' do
        visit project_path(project)

        within_testid('project-page-sidebar') do
          expect(page).not_to have_link('New file')
          expect(page).not_to have_link('Add README')
          expect(page).not_to have_link('Add CHANGELOG')
          expect(page).not_to have_link('Add CONTRIBUTING')
          expect(page).not_to have_link('Enable Auto DevOps')
          expect(page).not_to have_link('Auto DevOps enabled')
          expect(page).not_to have_link('Add Kubernetes cluster')
          expect(page).not_to have_link('Kubernetes')
        end
      end
    end

    describe 'as a maintainer' do
      before do
        project.add_maintainer(user)
        sign_in(user)

        visit project_path(project)
      end

      it '"New file" button linked to IDE new file page' do
        within_testid('project-buttons') do
          expect(page).to have_link('New file', href: presenter.ide_edit_path(project, project.default_branch || 'master'))
        end
      end

      it '"Add README" button linked to IDE new file populated for a README' do
        within_testid('project-buttons') do
          expect(page).to have_link('Add README', href: presenter.add_readme_ide_path)
        end
      end

      it '"Add license" button linked to IDE new file populated for a license' do
        within_testid('project-buttons') do
          expect(page).to have_link('Add LICENSE', href: presenter.add_license_ide_path)
        end
      end

      context 'Gitlab::CurrentSettings.default_branch_name is available' do
        before do
          expect(Gitlab::CurrentSettings)
            .to receive(:default_branch_name)
            .at_least(:once)
            .and_return('example_branch')

          visit project_path(project)
        end

        it '"New file" button linked to IDE new file page' do
          within_testid('project-buttons') do
            expect(page).to have_link('New file', href: presenter.ide_edit_path(project, 'example_branch'))
          end
        end
      end
    end
  end

  describe 'populated project' do
    let(:project) { create(:project, :public, :repository) }
    let(:presenter) { project.present(current_user: user) }

    describe 'as a normal user' do
      before do
        sign_in(user)

        visit project_path(project)
      end

      context 'when Auto DevOps is enabled' do
        it '"Auto DevOps enabled" button not linked' do
          visit project_path(project)

          within_testid('project-buttons') do
            expect(page).to have_text('Auto DevOps enabled')
          end
        end
      end

      context 'when Auto DevOps is not enabled' do
        let(:project) { create(:project, :public, :repository, auto_devops_attributes: { enabled: false }) }

        it 'no Auto DevOps button if can not manage pipelines' do
          within_testid('project-buttons') do
            expect(page).not_to have_link('Enable Auto DevOps')
            expect(page).not_to have_link('Auto DevOps enabled')
          end
        end

        it 'no Kubernetes cluster button if can not manage clusters' do
          within_testid('project-buttons') do
            expect(page).not_to have_link('Add Kubernetes cluster')
            expect(page).not_to have_link('Kubernetes')
          end
        end
      end
    end

    describe 'as a maintainer' do
      before do
        allow_any_instance_of(AutoDevopsHelper).to receive(:show_auto_devops_callout?).and_return(false)
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'README button' do
        before do
          allow(Project).to receive(:find_by_full_path)
                              .with(project.full_path, follow_redirects: true)
                              .and_return(project)
        end

        context 'when the project has a populated README' do
          it 'show the "README" anchor' do
            visit project_path(project)

            expect(project.repository.readme).not_to be_nil

            within_testid('project-buttons') do
              expect(page).not_to have_link('Add README', href: presenter.add_readme_ide_path)
              expect(page).to have_link('README', href: presenter.readme_path)
            end
          end

          context 'when the project has an empty README' do
            it 'show the "README" anchor' do
              allow(project.repository).to receive(:readme).and_return(fake_blob(path: 'README.md', data: '', size: 0))

              visit project_path(project)

              within_testid('project-buttons') do
                expect(page).not_to have_link('Add README', href: presenter.add_readme_path)
                expect(page).to have_link('README', href: presenter.readme_path)
              end
            end
          end
        end

        context 'when the project does not have a README' do
          it 'shows the single file editor "Add README" button' do
            allow(project.repository).to receive(:readme_path).and_return(nil)

            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).to have_link('Add README', href: presenter.add_readme_path)
            end
          end
        end
      end

      it 'no "Add CHANGELOG" button if the project already has a changelog' do
        visit project_path(project)

        expect(project.repository.changelog).not_to be_nil

        within_testid('project-buttons') do
          expect(page).not_to have_link('Add CHANGELOG')
        end
      end

      it 'no "Add license" button if the project already has a license' do
        visit project_path(project)

        expect(project.repository.license_blob).not_to be_nil

        within_testid('project-buttons') do
          expect(page).not_to have_link('Add LICENSE')
        end
      end

      it 'no "Add CONTRIBUTING" button if the project already has a contribution guide' do
        visit project_path(project)

        expect(project.repository.contribution_guide).not_to be_nil

        within_testid('project-buttons') do
          expect(page).not_to have_link('Add CONTRIBUTING')
        end
      end

      describe 'GitLab CI configuration button' do
        context 'when Auto DevOps is enabled' do
          it 'no "Set up CI/CD" button if the project has Auto DevOps enabled' do
            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).not_to have_link('Set up CI/CD')
            end
          end
        end

        context 'when Auto DevOps is not enabled' do
          let(:project) { create(:project, :public, :repository, auto_devops_attributes: { enabled: false }) }

          it '"Set up CI/CD" button linked to new file populated for a .gitlab-ci.yml' do
            visit project_path(project)

            expect(project.has_ci_config_file?).to eq(false)

            within_testid('project-buttons') do
              expect(page).to have_link('Set up CI/CD', href: project_ci_pipeline_editor_path(project))
            end
          end

          it '"Set up CI/CD" button is renamed if the project already has a .gitlab-ci.yml' do
            Files::CreateService.new(
              project,
              project.creator,
              start_branch: 'master',
              branch_name: 'master',
              commit_message: "Add .gitlab-ci.yml",
              file_path: '.gitlab-ci.yml',
              file_content: File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
            ).execute

            expect(project.has_ci_config_file?).to eq(true)

            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).not_to have_link('Set up CI/CD')
              expect(page).to have_link('CI/CD configuration')
            end
          end
        end
      end

      describe 'Auto DevOps button' do
        context 'when Auto DevOps is enabled' do
          it '"Auto DevOps enabled" anchor linked to settings page' do
            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).to have_link('Auto DevOps enabled', href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
            end
          end
        end

        context 'when Auto DevOps is not enabled' do
          let(:project) { create(:project, :public, :repository, auto_devops_attributes: { enabled: false }) }

          it '"Enable Auto DevOps" button linked to settings page' do
            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).to have_link('Enable Auto DevOps', href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
            end
          end

          it 'no Auto DevOps button if Auto DevOps callout is shown' do
            allow_any_instance_of(AutoDevopsHelper).to receive(:show_auto_devops_callout?).and_return(true)

            visit project_path(project)

            expect(page).to have_selector('.js-autodevops-banner')

            within_testid('project-buttons') do
              expect(page).not_to have_link('Enable Auto DevOps')
              expect(page).not_to have_link('Auto DevOps enabled')
            end
          end

          it 'no Auto DevOps button if builds feature is disabled' do
            project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)

            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).not_to have_link('Enable Auto DevOps')
              expect(page).not_to have_link('Auto DevOps enabled')
            end
          end

          it 'no "Enable Auto DevOps" button when .gitlab-ci.yml already exists' do
            Files::CreateService.new(
              project,
              project.creator,
              start_branch: 'master',
              branch_name: 'master',
              commit_message: "Add .gitlab-ci.yml",
              file_path: '.gitlab-ci.yml',
              file_content: File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
            ).execute

            expect(project.has_ci_config_file?).to eq(true)

            visit project_path(project)

            within_testid('project-buttons') do
              expect(page).not_to have_link('Enable Auto DevOps')
              expect(page).not_to have_link('Auto DevOps enabled')
            end
          end
        end
      end

      describe 'Kubernetes cluster button' do
        it '"Add Kubernetes cluster" button linked to clusters page' do
          visit project_path(project)

          within_testid('project-buttons') do
            expect(page).to have_link('Add Kubernetes cluster', href: project_clusters_path(project))
          end
        end

        it '"Kubernetes cluster" button linked to cluster page' do
          cluster = create(:cluster, :provided_by_gcp, projects: [project])

          visit project_path(project)

          within_testid('project-buttons') do
            expect(page).to have_link('Kubernetes', href: project_cluster_path(project, cluster))
          end
        end
      end
    end
  end
end
