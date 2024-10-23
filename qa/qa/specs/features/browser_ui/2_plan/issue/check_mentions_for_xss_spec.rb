# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, :health_check, product_group: :project_management do
    let!(:user) do
      create(:user,
        name: "QA User <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;",
        password: "pw_#{SecureRandom.hex(12)}",
        api_client: Runtime::API::Client.as_admin)
    end

    let!(:project) { create(:project, name: 'xss-test-for-mentions-project') }

    describe 'check xss occurence in @mentions in issues', :requires_admin do
      before do
        Flow::Login.sign_in

        project.add_member(user)

        create(:issue, project: project).visit!
      end

      it 'mentions a user in a comment', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347949' do
        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          show.comment("cc-ing you here @#{user.username}")

          expect do
            expect(show).to have_comment("cc-ing you here")
          end.not_to raise_error # Selenium::WebDriver::Error::UnhandledAlertError
        end
      end
    end
  end
end
