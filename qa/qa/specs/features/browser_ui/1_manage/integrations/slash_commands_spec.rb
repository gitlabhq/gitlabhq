# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', only: { subdomain: "staging-ref" } do
    describe 'Slack app integration', :slack, product_group: :import_and_integrate do
      context 'when using Slash commands' do
        # state to be seeded in the Slack UI
        let(:title) { "Issue - #{SecureRandom.hex(5)}" }
        let(:description) { "Description - #{SecureRandom.hex(6)}" }

        # state to be used in the GitLab API
        let(:project_name) { "project_with_slack" }
        let(:project) { create(:project, :with_readme, name: project_name) }

        before(:context) do
          Runtime::Env.require_slack_env!
        end

        before do
          authenticate_slack

          Flow::Login.sign_in_unless_signed_in
          Flow::Integrations::Slack.start_slack_install(project)

          with_slack_tab do
            break if Flow::Integrations::Slack.start_gitlab_connect(project, channel: 'test')

            with_tab(2) do
              Page::Profile::ChatNames::New.perform(&:authorize)
            end
            close_tab(2)
          end
        end

        it 'creates an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377890' do
          with_slack_tab do
            Vendor::Slack::Page::Chat.perform do |chat_page|
              chat_page.create_issue(project, channel: 'test', title: title, description: description)
            end

            aggregate_failures do
              expect { project.issues.size }.to eventually_be(1).within(max_duration: 10)

              issue = project.issues.last

              expect(issue.dig(:author, :username)).to eql(Runtime::User.username)
              expect(issue[:title]).to eql(title)
              expect(issue[:description]).to eql(description)
            end
          end
        end

        context 'with gitlab issue' do
          let!(:issue) { create(:issue, project: project) }
          let(:comment) { "Comment #{SecureRandom.hex(6)}" }

          it 'displays an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377891' do
            with_slack_tab do
              Vendor::Slack::Page::Chat.perform do |chat_page|
                chat_page.show_issue(project, channel: 'test', id: issue.iid)
              end

              expect { page.text }.to eventually_include(issue.title).within(max_duration: 10)
            end
          end

          it 'closes an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377892' do
            with_slack_tab do
              Vendor::Slack::Page::Chat.perform do |chat_page|
                chat_page.close_issue(project, channel: 'test', id: issue.iid)
              end

              expect { issue.state_events.last&.dig(:state) }.to eventually_eq('closed').within(max_duration: 10)
            end
          end

          it 'comments on an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377893' do
            with_slack_tab do
              Vendor::Slack::Page::Chat.perform do |chat_page|
                chat_page.comment_on_issue(project, channel: 'test', id: issue.iid, comment: comment)
              end

              expect { issue.comments.size }.to eventually_be(1).within(max_duration: 10)
              expect(issue.comments.first&.dig(:body)).to eql(comment), "Comments don't match: #{issue.comments}"
            end
          end

          context 'with target project' do
            let(:target) { create(:project, :with_readme, name: 'target_slack_project') }

            it 'moves an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377894' do
              with_slack_tab do
                Vendor::Slack::Page::Chat.perform do |chat_page|
                  chat_page.move_issue(project, target, channel: 'test', id: issue.iid)
                end

                expect { target.issues.size }.to eventually_be(1).within(max_duration: 10)

                target_issue = target.issues.first

                expect(target_issue&.dig(:title)).to eql(issue.title)
                expect(target_issue&.dig(:description)).to eql(issue.description)
              end
            end
          end
        end

        private

        def wait_until(timeout = 15, &block)
          Support::Waiter.wait_until(max_duration: timeout, reload_page: false, raise_on_failure: false, &block)
        end

        def with_slack_tab
          switch_to_tab(1)
          yield
          switch_to_tab(0)
        end

        def with_tab(idx)
          switch_to_tab(idx)
          page.refresh
          yield
        end

        def close_tab(idx)
          page.windows[idx].close
        end

        def switch_to_tab(idx)
          browser.switch_to.window(browser.window_handles[idx])
        end

        def authenticate_slack
          page.open_new_window

          with_slack_tab do
            Runtime::Browser.visit(
              Vendor::Slack::Address.base_url,
              Vendor::Slack::Page::Login
            )

            Vendor::Slack::Page::Login.perform(&:sign_in)
          end
        end

        def browser
          page.driver.browser
        end
      end
    end
  end
end
