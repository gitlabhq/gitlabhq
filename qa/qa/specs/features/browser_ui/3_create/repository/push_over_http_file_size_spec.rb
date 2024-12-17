# frozen_string_literal: true

module QA
  # This test modifies an instance level setting,
  # so skipping on live envs to avoid random transient issues
  RSpec.describe 'Create', :requires_admin, :skip_live_env, product_group: :source_code do
    describe 'push after setting the file size limit via admin/application_settings' do
      include Support::API

      let!(:project) { create(:project, :with_readme, name: 'project-test-push-limit') }

      after(:context) do
        set_file_size_limit(nil)
      end

      it(
        'push successful when the file size is under the limit',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347758'
      ) do
        set_file_size_limit(5)

        retry_on_fail do
          push = push_new_file('oversize_file_1.bin', wait_for_push: true)

          expect(push.output).not_to have_content 'remote: fatal: pack exceeds maximum allowed size'
        end
      end

      it(
        'push fails when the file size is above the limit',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347759'
      ) do
        set_file_size_limit(2)

        retry_on_fail do
          expect { push_new_file('oversize_file_2.bin', wait_for_push: false) }
            .to raise_error(QA::Support::Run::CommandError, /remote: fatal: pack exceeds maximum allowed size/)
        end
      end

      def set_file_size_limit(limit)
        request = Runtime::API::Request.new(Runtime::API::Client.as_admin, '/application/settings')
        response = put request.url, receive_max_input_size: limit

        expect(response.code).to eq(QA::Support::API::HTTP_STATUS_OK)
        expect(parse_body(response)[:receive_max_input_size]).to eq(limit)
      end

      def push_new_file(file_name, wait_for_push: true)
        commit_message = 'Adding a new file'
        output = Resource::Repository::Push.fabricate! do |p|
          p.repository_http_uri = project.repository_http_location.uri
          p.file_name = file_name
          p.file_content = SecureRandom.random_bytes(3000000)
          p.commit_message = commit_message
          p.new_branch = false
        end
        project.wait_for_push commit_message

        output
      end

      # Application settings are cached for up to a minute. So when we change
      # the `receive_max_input_size` setting, the setting might not be applied
      # for minute. This caused the tests to intermittently fail.
      # See https://gitlab.com/gitlab-org/quality/nightly/issues/113
      #
      # Instead of waiting a minute after changing the setting, we retry the
      # attempt to push if it fails. Most of the time the setting is updated in
      # under a minute, i.e., in fewer than 6 attempts with a 10 second sleep
      # between attempts.
      # See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/30233#note_188616863
      def retry_on_fail(&block)
        Support::Retrier.retry_on_exception(max_attempts: 6, reload_page: false, sleep_interval: 10, &block)
      end
    end
  end
end
