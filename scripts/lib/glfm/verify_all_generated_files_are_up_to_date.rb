# frozen_string_literal: true
require_relative 'constants'
require_relative 'shared'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#verify-all-generated-files-are-up-to-daterb-script
# for details on the implementation and usage of this script. This developers guide
# contains diagrams and documentation of this script,
# including explanations and examples of all files it reads and writes.
module Glfm
  class VerifyAllGeneratedFilesAreUpToDate
    include Constants
    include Shared

    def process
      verify_cmd = "git status --porcelain #{GLFM_SPEC_OUTPUT_PATH} #{EXAMPLE_SNAPSHOTS_PATH}"
      verify_cmd_output = run_external_cmd(verify_cmd)
      unless verify_cmd_output.empty?
        msg = "ERROR: Cannot run `#{__FILE__}` because `#{verify_cmd}` shows the following uncommitted changes:\n" \
          "#{verify_cmd_output}"
        raise(msg)
      end

      output('Verifying all generated files are up to date after running GLFM scripts...')

      output("Running `yarn install --frozen-lockfile` to ensure `yarn check-dependencies` doesn't fail...")
      run_external_cmd('yarn install --frozen-lockfile')

      # noinspection RubyMismatchedArgumentType
      update_specification_script = File.expand_path('../../glfm/update-specification.rb', __dir__)
      # noinspection RubyMismatchedArgumentType
      update_example_snapshots_script = File.expand_path('../../glfm/update-example-snapshots.rb', __dir__)

      output("Running `#{update_specification_script}`...")
      run_external_cmd(update_specification_script)

      output("Running `#{update_example_snapshots_script}`...")
      run_external_cmd(update_example_snapshots_script)

      output("Running `#{verify_cmd}` to check that no modifications to generated files have occurred...")
      verify_cmd_output = run_external_cmd(verify_cmd)

      return if verify_cmd_output.empty?

      raise "The following files were modified by running GLFM scripts. Please review, verify, and commit " \
        "the changes:\n#{verify_cmd_output}"
    end
  end
end
