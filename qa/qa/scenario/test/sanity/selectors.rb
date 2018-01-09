module QA
  module Scenario
    module Test
      module Sanity
        class Selectors < Scenario::Template
          include Scenario::Bootable

          PAGE_MODULES = [QA::Page]

          def perform(*)
            validators = PAGE_MODULES.map do |pages|
              Page::Validator.new(pages)
            end

            validators.map(&:errors).flatten.tap do |errors|
              break if errors.none?

              STDERR.puts <<~EOS
                GitLab QA sanity selectors validation test detected problems
                your merge request!

                The purpose of this tes is to make sure that GitLab QA tests,
                that are entirely black-box and click-driven scenario, do match
                pages structure / layout in the GitLab CE / EE repositories.

                It looks like you have changed views / pages / selectors, and
                these are now out of sync with what we have defined in `qa/`
                directory.

                Please update code in `qa/` directory to match currect changes
                in this merge request.

                For more help see documentation in `qa/page/README.md` file or
                ask for help on #qa channel on Slack (GitLab Team only).

                If you are not a team member, and you still need help to
                contribute, please open an issue in GitLab QA issue tracker.

                Please see errors described below.

              EOS

              STDERR.puts errors
            end

            validators.each(&:validate!)
          end
        end
      end
    end
  end
end
