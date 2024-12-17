# frozen_string_literal: true

module QA
  RSpec.shared_examples 'notifies on a pipeline' do |exit_code|
    before do
      push_commit(exit_code: exit_code)
    end

    it 'sends an email' do
      meta = exit_code_meta(exit_code)

      project.visit!
      Flow::Pipeline.wait_for_latest_pipeline(status: meta[:status])

      messages = mail_hog_messages(mail_hog)
      subjects = messages.map(&:subject)
      targets = messages.map(&:to)

      aggregate_failures do
        expect(subjects).to include(meta[:email_subject])
        expect(subjects).to include(/#{Regexp.escape(project.name)}/)
        expect(targets).to include(*emails)
      end
    end
  end

  RSpec.describe 'Manage', :orchestrated, :runner, :requires_admin, :smtp, product_group: :import_and_integrate do
    describe 'Pipeline status emails' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let(:emails) { %w[foo@bar.com baz@buzz.com] }
      let(:project) { create(:project, name: 'pipeline-status-project') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      let(:mail_hog) { Vendor::MailHog::API.new }

      before(:all) do
        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)
      end

      before do
        setup_pipeline_emails(emails)
      end

      describe 'when pipeline passes', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366240' do
        include_examples 'notifies on a pipeline', 0
      end

      describe 'when pipeline fails', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366241' do
        include_examples 'notifies on a pipeline', 1
      end

      def push_commit(exit_code: 0)
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml(exit_code: exit_code) }
        ])
      end

      def setup_pipeline_emails(emails)
        page.visit Runtime::Scenario.gitlab_address
        Flow::Login.sign_in_unless_signed_in

        project.visit!

        Page::Project::Menu.perform(&:go_to_integrations_settings)
        QA::Page::Project::Settings::Integrations.perform(&:click_pipelines_email_link)

        QA::Page::Project::Settings::Services::PipelineStatusEmails.perform do |pipeline_status_emails|
          pipeline_status_emails.toggle_notify_broken_pipelines # notify on pass and fail
          pipeline_status_emails.set_recipients(emails)
          pipeline_status_emails.click_save_button
        end
      end

      def gitlab_ci_yaml(exit_code: 0, tag: executor)
        <<~YAML
          test-pipeline-email:
            tags:
              - #{tag}
            script: sleep 5; exit #{exit_code};
        YAML
      end

      private

      def exit_code_meta(exit_code)
        {
          0 => { status: 'Passed', email_subject: /Successful pipeline/ },
          1 => { status: 'Failed', email_subject: /Failed pipeline/ }
        }[exit_code]
      end

      def mail_hog_messages(mail_hog_api)
        Support::Retrier.retry_until(sleep_interval: 1) do
          Runtime::Logger.debug('Fetching email...')

          messages = mail_hog_api.fetch_messages
          logs = messages.map { |m| "#{m.to}: #{m.subject}" }

          Runtime::Logger.debug("MailHog Logs: #{logs.join("\n")}")

          # for failing pipelines we have three messages
          # one for the owner
          # and one for each recipient
          messages if mail_hog_pipeline_count(messages) >= 2
        end
      end

      def mail_hog_pipeline_count(messages)
        messages.count { |message| message.subject.include?('pipeline') }
      end
    end
  end
end
