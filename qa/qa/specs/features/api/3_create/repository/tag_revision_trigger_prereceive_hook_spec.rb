# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Prereceive hook', product_group: :source_code do
      # NOTE: this test requires a global server hook to be configured in the target test environment.
      # If running this test against a local GDK installation, please follow the instructions in the
      # following guide to set up the hook:
      # https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/testing_guide/end_to_end/running_tests_that_require_special_setup.md#tests-that-require-a-global-server-hook

      let(:project) { create(:project, :with_readme) }

      context 'when creating a tag for a ref' do
        context 'when it triggers a prereceive hook configured with a custom error' do
          before do
            # The configuration test prereceive hook must match a specific naming pattern
            # In this test we create a project with a different name and then change the path.
            # Otherwise we wouldn't be able create any commits to be tagged due to the hook.
            project.change_path("project-reject-prereceive-#{SecureRandom.hex(8)}")
          end

          it 'returns a custom server hook error', :skip_live_env,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/369053' do
            expect { project.create_repository_tag('v1.2.3') }
              .to raise_error.with_message(
                /rejecting prereceive hook for projects with GL_PROJECT_PATH matching pattern reject-prereceive/
              )
          end
        end
      end
    end
  end
end
