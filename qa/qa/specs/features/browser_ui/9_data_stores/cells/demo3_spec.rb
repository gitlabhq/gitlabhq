# frozen_string_literal: true

# version of the login test that only runs against GDK
# implements functionality in https://gitlab.com/gitlab-org/gitlab/-/issues/420118

module QA
  RSpec.describe 'Data Stores', :skip_live_env, :requires_admin, product_group: :tenant_scale do
    describe 'Demo 3' do
      let(:debug) { false }
      let(:cell1_url) { ENV.fetch('CELL1_URL', 'http://gdk.test:3000/') }
      let(:cell2_url) { ENV.fetch('CELL2_URL', 'http://gdk.test:3001/') }
      let(:cell1_group_name) { "cell1-group-#{SecureRandom.hex(8)}" }
      let(:cell2_group_name) { "cell2-group-#{SecureRandom.hex(8)}" }
      let(:cell1_project_name) { "cell1-project-#{SecureRandom.hex(8)}" }
      let(:cell2_project_name) { "cell2-project-#{SecureRandom.hex(8)}" }

      def create_group(name)
        Resource::Group.new.fabricate_group!(group_name: name)

        Page::Group::Show.perform do |group_show|
          # Ensure that the group was actually created
          group_show.wait_until(sleep_interval: 1) do
            expect(group_show).to have_text(name)
          end
        end
      end

      def create_project(group_name, project_name)
        Page::Main::Menu.perform(&:go_to_create_project)
        Page::Project::New.perform(&:click_blank_project_link)
        Page::Project::New.perform do |project_page|
          project_page.choose_namespace(group_name)
          project_page.choose_name(project_name)
          project_page.create_new_project
        end
      end

      it('walkthrough',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/434422',
        only: { condition: -> { !Runtime::Env.running_in_ci? } }
      ) do
        Runtime::Scenario.define(:gitlab_address, cell1_url)
        # Sign in Cell 1
        Flow::Login.sign_in
        Page::Main::Menu.perform(&:go_to_groups)
        # Create Group on Cell 1
        create_group(cell1_group_name)

        # Create a Project in that group on Cell 1
        create_project(cell1_group_name, cell1_project_name)

        # Cell 1 Project shows
        page.visit "#{cell1_url}#{cell1_group_name}/#{cell1_project_name}"
        Page::Project::Show.perform do |project|
          expect(project.has_name?(cell1_project_name)).to be true
        end

        # Visit Cell 2
        page.visit cell2_url
        Page::Main::Menu.perform(&:go_to_groups)

        # Cell 1 group does not show
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard.has_group?(cell1_group_name)).to be(false)
          end
        end

        # Cell 1 project does not show
        page.visit "#{cell2_url}#{cell1_group_name}/#{cell1_project_name}"
        expect(page).to have_text('Page not found')

        page.visit cell2_url
        Page::Main::Menu.perform(&:go_to_groups)
        # Create Group on Cell 2
        create_group(cell2_group_name)

        # Create a Project in that group on Cell 2
        # TODO: this functionality is under development, uncomment when complete
        # create_project(cell2_group_name,cell2_project_name)

        # Cell 2 Project shows
        # page.visit "#{cell2_url}#{cell2_group_name}/#{cell2_project_name}"
        # Page::Project::Show.perform do |project|
        #  expect(project.has_name?(cell2_project_name)).to be true
        # end

        # Visit Cell 1
        page.visit cell1_url
        Page::Main::Menu.perform(&:go_to_groups)

        # Cell 1 group does shows
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).to have_group(cell1_group_name)
          end
        end

        # Cell 1 Project shows
        page.visit "#{cell1_url}#{cell1_group_name}/#{cell1_project_name}"
        Page::Project::Show.perform do |project|
          expect(project).to have_name(cell1_project_name)
        end

        # Cell 2 group does not shows
        # TODO: this functionality is under development, uncomment when complete
        # Page::Dashboard::Groups.perform do |group_dashboard|
        #   group_dashboard.wait_until(sleep_interval: 1) do
        #     expect(group_dashboard.has_group?(cell2_group_name)).to be(false)
        #   end
        # end

        # Cell 2 Project does not show
        page.visit "#{cell1_url}#{cell2_group_name}/#{cell2_project_name}"
        expect(page).to have_text('Page not found')

        # Visit Cell 2
        page.visit cell2_url
        Page::Main::Menu.perform(&:go_to_groups)

        # Cell 1 group does not shows
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).not_to have_group(cell1_group_name)
          end
        end

        # Cell 1 project does not show
        page.visit "#{cell2_url}#{cell1_group_name}/#{cell1_project_name}"
        expect(page).to have_text('Page not found')

        # Cell 2 group does show
        page.visit cell2_url
        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).to have_group(cell2_group_name)
          end
        end

        # Cell 2 project does show
        # TODO: this functionality is under development, uncomment when complete
        # page.visit "#{cell2_url}#{cell2_group_name}/#{cell2_project_name}"
        # Page::Project::Show.perform do |project|
        #  expect(project.has_name?(cell2_project_name)).to be true
        # end
      end
    end
  end
end
