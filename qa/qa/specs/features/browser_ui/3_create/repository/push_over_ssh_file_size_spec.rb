# frozen_string_literal: true

module QA
  # This test modifies an instance-level setting,
  # so skipping on live environments to avoid transient issues.
  RSpec.describe 'Create', :requires_admin, :skip_live_env, product_group: :source_code do
    describe 'push after setting the file size limit via admin/application_settings using SSH' do
      include Support::API

      let!(:project) { create(:project, name: 'project-test-push-limit') }
      let(:key) { create(:ssh_key, title: "key for ssh tests #{Time.now.to_f}") }
      let(:commit_message) { 'Adding a new file' }

      after(:context) do
        set_file_size_limit(nil)
      end

      it(
        'push is successful when the file size is under the limit',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/523543'
      ) do
        set_file_size_limit(5) # Set a 5MB file size limit

        retry_on_fail do
          push = push_new_file('oversize_file_1.bin')

          push.project.visit!
          Page::Project::Show.perform do |project|
            expect(project).to have_commit_message(commit_message)
          end
        end
      end

      it(
        'push fails when the file size is above the limit',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/523544'
      ) do
        set_file_size_limit(2) # Set a 2MB file size limit

        retry_on_fail do
          expect { push_new_file('oversize_file_2.bin') }
            .to raise_error(QA::Support::Run::CommandError, /remote: fatal: pack exceeds maximum allowed size/)
        end
      end

      def set_file_size_limit(limit)
        request = Runtime::API::Request.new(Runtime::API::Client.as_admin, '/application/settings')
        response = put request.url, receive_max_input_size: limit

        expect(response.code).to eq(QA::Support::API::HTTP_STATUS_OK)
        expect(parse_body(response)[:receive_max_input_size]).to eq(limit)
      end

      def push_new_file(file_name)
        Resource::Repository::ProjectPush.fabricate! do |p|
          p.project = project
          p.ssh_key = key
          p.file_name = file_name
          p.file_content = SecureRandom.random_bytes(3_000_000) # 3MB file
          p.commit_message = commit_message
        end
      end

      # Application settings are cached for up to a minute.
      # Instead of waiting, retry the attempt to push if it fails.
      def retry_on_fail(&block)
        Support::Retrier.retry_on_exception(max_attempts: 6, reload_page: false, sleep_interval: 10, &block)
      end
    end
  end
end
