# frozen_string_literal: true

module QA
  RSpec.describe(
    'Create',
    :runner,
    # TODO: remove limitation to only run on main when the bug is fixed
    only: { pipeline: :main },
    quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/338179',
      type: :bug
    },
    feature_flag: { name: 'vscode_web_ide', scope: :project },
    product_group: :editor
  ) do
    describe 'Web IDE web terminal' do
      before do
        Runtime::Feature.disable(:vscode_web_ide, project: project)
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'web-terminal-project'
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab/.gitlab-webide.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab/.gitlab-webide.yml',
                content: <<~YAML
                  terminal:
                    tags: ["web-ide"]
                    script: sleep 60
                YAML
              }
            ]
          )
        end

        @runner = Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = %w[web-ide]
          runner.image = 'gitlab/gitlab-runner:latest'
          runner.config = <<~END
            concurrent = 1

            [session_server]
              listen_address = "0.0.0.0:8093"
              advertise_address = "localhost:8093"
              session_timeout = 120
          END
        end

        Flow::Login.sign_in

        project.visit!
      end

      after do
        Runtime::Feature.enable(:vscode_web_ide, project: project)
        @runner.remove_via_api! if @runner
      end

      it 'user starts the web terminal', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347737' do
        Page::Project::Show.perform(&:open_web_ide!)

        # Start the web terminal and check that there were no errors
        # The terminal screen is a canvas element, so we can't read its content,
        # so we infer that it's working if:
        #  a) The terminal JS package has loaded, and
        #  b) It's not stuck in a "Loading/Starting" state, and
        #  c) There's no alert stating there was a problem
        #  d) There are no JS console errors
        #
        # The terminal itself is a third-party package so we assume it is
        # adequately tested elsewhere.
        #
        # There are also FE specs
        # * spec/frontend/ide/components/terminal/terminal_controls_spec.js
        Page::Project::WebIDE::Edit.perform do |edit|
          edit.wait_until_ide_loads
          edit.start_web_terminal

          expect(edit).to have_no_alert
          expect(edit).to have_finished_loading
          expect(edit).to have_terminal_screen
        end

        # It takes a few seconds for console errors to appear
        sleep 3

        errors = page.driver.browser.logs.get(:browser)
                     .select { |e| e.level == "SEVERE" }
                     .to_a

        if errors.present?
          raise("Console error(s):\n#{errors.join("\n\n")}")
        end
      end
    end
  end
end
