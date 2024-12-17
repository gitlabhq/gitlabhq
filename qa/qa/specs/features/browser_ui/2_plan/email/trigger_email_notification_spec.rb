# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :orchestrated, :smtp, :requires_admin, product_group: :project_management do
    describe 'Email Notification' do
      include Support::API

      let!(:user) { create(:user) }

      let(:project) { create(:project, name: 'email-notification-test') }

      before do
        Flow::Login.sign_in
      end

      it 'is received by a user for project invitation', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347961' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_members)
        Page::Project::Members.perform do |member_settings|
          member_settings.add_member(user.username)
        end

        expect(page).to have_content("@#{user.username}")

        mailhog_items = mailhog_json['items']

        expect(mailhog_items).to include(an_object_satisfying { |o| mailhog_item_subject(o)&.include?('project was granted') })
      end

      private

      def mailhog_json
        Support::Retrier.retry_until(sleep_interval: 1) do
          Runtime::Logger.debug(%(retrieving "#{QA::Runtime::MailHog.api_messages_url}"))

          mailhog_response = get QA::Runtime::MailHog.api_messages_url

          mailhog_data = JSON.parse(mailhog_response.body)
          total = mailhog_data['total']
          subjects = mailhog_data['items']
            .map { |item| mailhog_item_subject(item) }

          Runtime::Logger.debug(%(Total number of emails: #{total}))
          Runtime::Logger.debug(%(Subjects:\n#{subjects.join("\n")}))

          # Expect at least two invitation messages: group and project
          mailhog_data if mailhog_project_message_count(subjects) >= 1
        end
      end

      def mailhog_item_subject(item)
        item.dig('Content', 'Headers', 'Subject', 0)
      end

      def mailhog_project_message_count(subjects)
        subjects.count { |subject| subject.include?('project was granted') }
      end
    end
  end
end
