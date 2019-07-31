# frozen_string_literal: true

module QA
  context 'Create', :requires_admin do
    describe 'push after setting the file size limit via admin/application_settings' do
      before(:context) do
        @project = Resource::Project.fabricate_via_api! do |p|
          p.name = 'project-test-push-limit'
          p.initialize_with_readme = true
        end

        @api_client = Runtime::API::Client.new(:gitlab, personal_access_token: Runtime::Env.admin_personal_access_token)
      end

      after(:context) do
        # need to set the default value after test
        # default value for file size limit is empty
        set_file_size_limit(nil)
      end

      it 'push successful when the file size is under the limit' do
        set_file_size_limit(5)

        retry_on_fail do
          push = push_new_file('oversize_file_1.bin', wait_for_push: true)

          expect(push.output).not_to have_content 'remote: fatal: pack exceeds maximum allowed size'
        end
      end

      it 'push fails when the file size is above the limit' do
        set_file_size_limit(1)

        retry_on_fail do
          expect { push_new_file('oversize_file_2.bin', wait_for_push: false) }
            .to raise_error(QA::Git::Repository::RepositoryCommandError, /remote: fatal: pack exceeds maximum allowed size/)
        end
      end

      def set_file_size_limit(limit)
        request = Runtime::API::Request.new(@api_client, '/application/settings')
        put request.url, receive_max_input_size: limit

        expect_status(200)
        expect(json_body).to match(
          a_hash_including(receive_max_input_size: limit)
        )
      end

      def push_new_file(file_name, wait_for_push: true)
        commit_message = 'Adding a new file'
        output = Resource::Repository::Push.fabricate! do |p|
          p.repository_http_uri = @project.repository_http_location.uri
          p.file_name = file_name
          p.file_content = SecureRandom.random_bytes(2000000)
          p.commit_message = commit_message
          p.new_branch = false
        end
        @project.wait_for_push commit_message

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
      # See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/30233#note_188616863
      def retry_on_fail
        Support::Retrier.retry_on_exception(max_attempts: 6, reload_page: nil, sleep_interval: 10) do
          yield
        end
      end
    end
  end
end
