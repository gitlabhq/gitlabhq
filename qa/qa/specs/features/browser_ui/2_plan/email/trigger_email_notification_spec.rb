# frozen_string_literal: true

module QA
  context 'Plan', :orchestrated, :smtp do
    describe 'Email Notification' do
      let(:user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'email-notification-test'
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'is received by a user for project invitation' do
        Flow::Project.add_member(project: project, username: user.username)

        expect(page).to have_content(/@#{user.username}(\n| )?Given access/)

        mailhog_items = mailhog_json.dig('items')

        expect(mailhog_items).to include(an_object_satisfying { |o| /project was granted/ === o.dig('Content', 'Headers', 'Subject', 0) })
      end

      private

      def mailhog_json
        Support::Retrier.retry_until(sleep_interval: 1) do
          Runtime::Logger.debug(%Q[retrieving "#{QA::Runtime::MailHog.api_messages_url}"])

          mailhog_response = get QA::Runtime::MailHog.api_messages_url

          mailhog_data = JSON.parse(mailhog_response.body)

          # Expect at least two invitation messages: group and project
          mailhog_data if mailhog_data.dig('total') >= 2
        end
      end
    end
  end
end
