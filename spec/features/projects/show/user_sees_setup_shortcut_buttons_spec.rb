require 'spec_helper'

describe 'Projects > Show > User sees setup shortcut buttons' do
  # For "New file", "Add License" functionality,
  # see spec/features/projects/files/project_owner_creates_license_file_spec.rb
  # see spec/features/projects/files/project_owner_sees_link_to_create_license_file_in_empty_project_spec.rb

  let(:user) { create(:user) }

  describe 'empty project' do
    let(:project) { create(:project, :public, :empty_repo) }
    let(:presenter) { project.present(current_user: user) }

    describe 'as a normal user' do
      before do
        sign_in(user)

        visit project_path(project)
      end

      it 'no Auto DevOps button if can not manage pipelines' do
        page.within('.project-stats') do
          expect(page).not_to have_link('Enable Auto DevOps')
          expect(page).not_to have_link('Auto DevOps enabled')
        end
      end

      it '"Auto DevOps enabled" button not linked' do
        project.create_auto_devops!(enabled: true)

        visit project_path(project)

        page.within('.project-stats') do
          expect(page).to have_text('Auto DevOps enabled')
        end
      end
    end

    describe 'as a master' do
      before do
        project.add_master(user)
        sign_in(user)

        visit project_path(project)
      end

      it '"New file" button linked to new file page' do
        page.within('.project-stats') do
          expect(page).to have_link('New file', href: project_new_blob_path(project, project.default_branch || 'master'))
        end
      end

      it '"Add Readme" button linked to new file populated for a readme' do
        page.within('.project-stats') do
          expect(page).to have_link('Add Readme', href: presenter.add_readme_path)
        end
      end

      it '"Add License" button linked to new file populated for a license' do
        page.within('.project-stats') do
          expect(page).to have_link('Add License', href: presenter.add_license_path)
        end
      end

      describe 'Auto DevOps button' do
        it '"Enable Auto DevOps" button linked to settings page' do
          page.within('.project-stats') do
            expect(page).to have_link('Enable Auto DevOps', href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
          end
        end

        it '"Auto DevOps enabled" anchor linked to settings page' do
          project.create_auto_devops!(enabled: true)

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).to have_link('Auto DevOps enabled', href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
          end
        end
      end

      describe 'Kubernetes cluster button' do
        it '"Add Kubernetes cluster" button linked to clusters page' do
          page.within('.project-stats') do
            expect(page).to have_link('Add Kubernetes cluster', href: new_project_cluster_path(project))
          end
        end

        it '"Kubernetes cluster" anchor linked to cluster page' do
          cluster = create(:cluster, :provided_by_gcp, projects: [project])

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).to have_link('Kubernetes configured', href: project_cluster_path(project, cluster))
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

      it 'no Auto DevOps button if can not manage pipelines' do
        page.within('.project-stats') do
          expect(page).not_to have_link('Enable Auto DevOps')
          expect(page).not_to have_link('Auto DevOps enabled')
        end
      end

      it '"Auto DevOps enabled" button not linked' do
        project.create_auto_devops!(enabled: true)

        visit project_path(project)

        page.within('.project-stats') do
          expect(page).to have_text('Auto DevOps enabled')
        end
      end

      it 'no Kubernetes cluster button if can not manage clusters' do
        page.within('.project-stats') do
          expect(page).not_to have_link('Add Kubernetes cluster')
          expect(page).not_to have_link('Kubernetes configured')
        end
      end
    end

    describe 'as a master' do
      before do
        allow_any_instance_of(AutoDevopsHelper).to receive(:show_auto_devops_callout?).and_return(false)
        project.add_master(user)
        sign_in(user)

        visit project_path(project)
      end

      it 'no "Add Changelog" button if the project already has a changelog' do
        expect(project.repository.changelog).not_to be_nil

        page.within('.project-stats') do
          expect(page).not_to have_link('Add Changelog')
        end
      end

      it 'no "Add License" button if the project already has a license' do
        expect(project.repository.license_blob).not_to be_nil

        page.within('.project-stats') do
          expect(page).not_to have_link('Add License')
        end
      end

      it 'no "Add Contribution guide" button if the project already has a contribution guide' do
        expect(project.repository.contribution_guide).not_to be_nil

        page.within('.project-stats') do
          expect(page).not_to have_link('Add Contribution guide')
        end
      end

      describe 'GitLab CI configuration button' do
        it '"Set up CI/CD" button linked to new file populated for a .gitlab-ci.yml' do
          expect(project.repository.gitlab_ci_yml).to be_nil

          page.within('.project-stats') do
            expect(page).to have_link('Set up CI/CD', href: presenter.add_ci_yml_path)
          end
        end

        it 'no "Set up CI/CD" button if the project already has a .gitlab-ci.yml' do
          Files::CreateService.new(
            project,
            project.creator,
            start_branch: 'master',
            branch_name: 'master',
            commit_message: "Add .gitlab-ci.yml",
            file_path: '.gitlab-ci.yml',
            file_content: File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
          ).execute

          expect(project.repository.gitlab_ci_yml).not_to be_nil

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).not_to have_link('Set up CI/CD')
          end
        end

        it 'no "Set up CI/CD" button if the project has Auto DevOps enabled' do
          project.create_auto_devops!(enabled: true)

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).not_to have_link('Set up CI/CD')
          end
        end
      end

      describe 'Auto DevOps button' do
        it '"Enable Auto DevOps" button linked to settings page' do
          page.within('.project-stats') do
            expect(page).to have_link('Enable Auto DevOps', href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
          end
        end

        it '"Enable Auto DevOps" button linked to settings page' do
          project.create_auto_devops!(enabled: true)

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).to have_link('Auto DevOps enabled', href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
          end
        end

        it 'no Auto DevOps button if Auto DevOps callout is shown' do
          allow_any_instance_of(AutoDevopsHelper).to receive(:show_auto_devops_callout?).and_return(true)

          visit project_path(project)

          expect(page).to have_selector('.js-autodevops-banner')

          page.within('.project-stats') do
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

          expect(project.repository.gitlab_ci_yml).not_to be_nil

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).not_to have_link('Enable Auto DevOps')
            expect(page).not_to have_link('Auto DevOps enabled')
          end
        end
      end

      describe 'Kubernetes cluster button' do
        it '"Add Kubernetes cluster" button linked to clusters page' do
          page.within('.project-stats') do
            expect(page).to have_link('Add Kubernetes cluster', href: new_project_cluster_path(project))
          end
        end

        it '"Kubernetes cluster" button linked to cluster page' do
          cluster = create(:cluster, :provided_by_gcp, projects: [project])

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).to have_link('Kubernetes configured', href: project_cluster_path(project, cluster))
          end
        end
      end

      describe '"Set up Koding" button' do
        it 'no "Set up Koding" button if Koding disabled' do
          stub_application_setting(koding_enabled?: false)

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).not_to have_link('Set up Koding')
          end
        end

        it 'no "Set up Koding" button if the project already has a .koding.yml' do
          stub_application_setting(koding_enabled?: true)
          allow(Gitlab::CurrentSettings.current_application_settings).to receive(:koding_url).and_return('http://koding.example.com')
          expect(project.repository.changelog).not_to be_nil
          allow_any_instance_of(Repository).to receive(:koding_yml).and_return(project.repository.changelog)

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).not_to have_link('Set up Koding')
          end
        end

        it '"Set up Koding" button linked to new file populated for a .koding.yml' do
          stub_application_setting(koding_enabled?: true)

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).to have_link('Set up Koding', href: presenter.add_koding_stack_path)
          end
        end
      end
    end
  end
end
