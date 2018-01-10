module QA
  module Scenario
    module Test
      module Sanity
        class Selectors < Scenario::Template
          include Scenario::Bootable

          PAGES = [QA::Page].freeze

          def perform(*)
            validators = PAGES.map do |pages|
              Page::Validator.new(pages)
            end

            validators.map(&:errors).flatten.tap do |errors|
              break if errors.none?

              warn <<~EOS
                GitLab QA sanity selectors validation test detected problems
                with your merge request!

                The purpose of this test is to make sure that GitLab QA tests,
                that are entirely black-box, click-driven scenarios, do match
                pages structure / layout in GitLab CE / EE repositories.

                It looks like you have changed views / pages / selectors, and
                these are now out of sync with what we have defined in `qa/`
                directory.

                Please update the code in `qa/` directory to make it match
                current changes in this merge request.

                For more help see documentation in `qa/page/README.md` file or
                ask for help on #qa channel on Slack (GitLab Team only).

                If you are not a Team Member, and you still need help to
                contribute, please open an issue in GitLab QA issue tracker.

                Please see errors described below.

              EOS

              warn errors
            end

            validators.each(&:validate!)

            puts 'Views / selectors validation passed!'
          end
        end
      end
    end
  end
end
