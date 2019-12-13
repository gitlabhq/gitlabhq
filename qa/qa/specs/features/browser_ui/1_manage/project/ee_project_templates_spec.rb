# frozen_string_literal: true
require 'securerandom'

module QA
  context :manage do
    describe 'Project templates' do
      before(:all) do
        @files = [
            {
                name: 'file.txt',
                content: 'foo'
            },
            {
                name: 'README.md',
                content: 'bar'
            }
        ]

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @template_container_group_name = "instance-template-container-group-#{SecureRandom.hex(8)}"

        template_container_group = QA::Resource::Group.fabricate! do |group|
          group.path = @template_container_group_name
          group.description = 'Instance template container group'
        end

        @template_project = Resource::Project.fabricate! do |project|
          project.name = 'template-project-1'
          project.group = template_container_group
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @template_project
          push.files = @files
          push.commit_message = 'Add test files'
        end
      end

      # Failure issue: https://gitlab.com/gitlab-org/quality/staging/issues/51
      context 'instance level', :quarantine do
        before do
          # Log out if already logged in
          Page::Main::Menu.perform do |menu|
            menu.sign_out if menu.has_personal_area?(wait: 0)
          end

          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform(&:sign_in_using_admin_credentials)

          Page::Main::Menu.perform(&:click_admin_area)
          Page::Admin::Menu.perform(&:go_to_template_settings)

          EE::Page::Admin::Settings::Templates.perform do |page|
            page.choose_custom_project_template("#{@template_container_group_name}")
          end

          group = Resource::Group.fabricate_via_api!
          group.visit!

          Page::Group::Show.perform(&:go_to_new_project)

          Page::Project::New.perform(&:go_to_create_from_template_instance_tab)
        end

        it 'successfully imports the project using template' do
          Page::Project::New.perform do |page|
            expect(page.instance_template_tab_badge_text).to eq "1"
            expect(page).to have_text(@template_project.name)
          end

          create_project_using_template(project_name: 'Project using instance level project template',
                                        namespace: Runtime::Namespace.path,
                                        template_name: @template_project.name)

          Page::Project::Show.perform(&:wait_for_import_success)
          @files.each do |file|
            expect(page).to have_content(file[:name])
          end
        end
      end

      context 'group level' do
        before do
          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform(&:sign_in_using_credentials)

          Page::Main::Menu.perform(&:go_to_groups)
          Page::Dashboard::Groups.perform { |page| page.click_group(Runtime::Namespace.sandbox_name) }
          Page::Project::Menu.perform(&:click_settings)

          EE::Page::Group::Settings::General.perform do |settings|
            settings.choose_custom_project_template("#{@template_container_group_name}")
          end

          group = Resource::Group.fabricate_via_api!
          group.visit!

          Page::Group::Show.perform(&:go_to_new_project)

          Page::Project::New.perform(&:go_to_create_from_template_group_tab)
        end

        it 'successfully imports the project using template' do
          Page::Project::New.perform do |page|
            expect(page.group_template_tab_badge_text).to eq "1"
            expect(page).to have_text(@template_container_group_name)
            expect(page).to have_text(@template_project.name)
          end

          create_project_using_template(project_name: 'Project using group level project template',
                                        namespace: Runtime::Namespace.sandbox_name,
                                        template_name: @template_project.name)

          Page::Project::Show.perform(&:wait_for_import_success)
          @files.each do |file|
            expect(page).to have_content(file[:name])
          end
        end
      end

      def create_project_using_template(project_name:, namespace:, template_name:)
        Page::Project::New.perform do |page|
          page.use_template_for_project(template_name)
          page.choose_namespace(namespace)
          page.choose_name("#{project_name} #{SecureRandom.hex(8)}")
          page.add_description("#{project_name}")
          page.set_visibility('Public')
          page.create_new_project
        end
      end
    end
  end
end
