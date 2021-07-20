# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :orchestrated, :smtp, :requires_admin do
    describe 'Email Notification' do
      include Support::Api

      let!(:user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'email-notification-test'
        end
      end

      before do
        Runtime::Feature.enable(:invite_members_group_modal)
        Flow::Login.sign_in
      end

      it 'is received by a user for project invitation', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/676' do
        project.visit!

        Page::Project::Menu.perform(&:click_members)
        Page::Project::Members.perform do |member_settings|
          member_settings.add_member(user.username)
        end

        expect(page).to have_content("@#{user.username}")

        mailhog_items = mailhog_json.dig('items')

        expect(mailhog_items).to include(an_object_satisfying { |o| /project was granted/ === mailhog_item_subject(o) })
      end

      private

      def mailhog_json
        Support::Retrier.retry_until(sleep_interval: 1) do
          Runtime::Logger.debug(%Q[retrieving "#{QA::Runtime::MailHog.api_messages_url}"])

          mailhog_response = get QA::Runtime::MailHog.api_messages_url

          mailhog_data = JSON.parse(mailhog_response.body)
          total = mailhog_data.dig('total')
          subjects = mailhog_data.dig('items')
            .map(&method(:mailhog_item_subject))
            .join("\n")

          Runtime::Logger.debug(%Q[Total number of emails: #{total}])
          Runtime::Logger.debug(%Q[Subjects:\n#{subjects}])

          # Expect at least two invitation messages: group and project
          mailhog_data if total >= 2
        end
      end

      def mailhog_item_subject(item)
        item.dig('Content', 'Headers', 'Subject', 0)
      end
    end
  end
end
