# frozen_string_literal: true

# version of the login test that only runs against GDK
# implements functionality in https://gitlab.com/gitlab-org/gitlab/-/issues/415207

module QA
  RSpec.describe 'Data Stores', :skip_live_env, :requires_admin, product_group: :tenant_scale do
    describe 'Demo 2' do
      let(:cell1_url) { ENV.fetch('CELL1_URL', 'http://gdk.test:3000/') }
      let(:cell2_url) { ENV.fetch('CELL2_URL', 'http://gdk.test:3001/') }
      let(:cell1_group_name) { "cell1-group-#{SecureRandom.hex(8)}" }
      let(:cell2_group_name) { "cell2-group-#{SecureRandom.hex(8)}" }

      before do
        ENV['PERSONAL_ACCESS_TOKENS_DISABLED'] = 'true' # force off creating by api so walk through demo
      end

      it('walkthrough',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/434421',
        only: { condition: -> { !Runtime::Env.running_in_ci? } }
      ) do
        # Sign in Cell 1
        Runtime::Scenario.define(:gitlab_address, cell1_url)
        Flow::Login.sign_in
        Page::Main::Menu.perform(&:go_to_groups)
        # Create Group on Cell 1
        Resource::Group.new.fabricate_group!(group_name: cell1_group_name)

        # Cell 1 Group exists on Cell 1
        Page::Group::Show.perform do |group_show|
          # Ensure that the group was actually created
          group_show.wait_until(sleep_interval: 1) do
            expect(group_show).to have_text(cell1_group_name)
          end
        end

        # Visit Cell 2
        page.visit cell2_url
        Runtime::Scenario.define(:gitlab_address, cell2_url)
        Page::Main::Menu.perform(&:go_to_groups)

        # Cell 1 group does not show
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).not_to have_group(cell1_group_name)
          end
        end

        # Create Group on Cell 2
        Resource::Group.new.fabricate_group!(group_name: cell2_group_name)

        # Cell 2 Group exists on Cell 2
        Page::Group::Show.perform do |group_show|
          # Ensure that the group was actually created
          group_show.wait_until(sleep_interval: 1) do
            expect(group_show).to have_text(cell2_group_name)
          end
        end

        # Visit Cell 1
        page.visit cell1_url
        Page::Main::Menu.perform(&:go_to_groups)

        # Cell 1 group appears
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).to have_group(cell1_group_name)
          end
        end

        # Cell 2 group does not appear
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).not_to have_group(cell2_group_name)
          end
        end

        # Visit Cell 2
        page.visit cell2_url
        Page::Main::Menu.perform(&:go_to_groups)

        # Cell 1 group does not shows
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).not_to have_group(cell1_group_name)
          end
        end

        # Cell 2 group does show
        Page::Dashboard::Groups.perform do |group_dashboard|
          group_dashboard.wait_until(sleep_interval: 1) do
            expect(group_dashboard).to have_group(cell2_group_name)
          end
        end
      end
    end
  end
end
