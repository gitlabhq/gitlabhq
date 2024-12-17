# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe(
      'WebHooks integration',
      :requires_admin,
      :integrations,
      :orchestrated,
      product_group: :import_and_integrate,
      feature_flag: { name: :auto_disabling_web_hooks }
    ) do
      before(:context) do
        toggle_local_requests(true)
      end

      after(:context) do
        Resource::ProjectWebHook.teardown!
      end

      let(:session) { SecureRandom.hex(5) }
      let(:tag_name) { SecureRandom.hex(5) }

      it 'sends a push event', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348945' do
        Resource::ProjectWebHook.setup(session: session, push: true) do |webhook, smocker|
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          expect_web_hook_single_event_success(webhook, smocker, type: 'push')
        end
      end

      it 'sends a merge request event', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349720' do
        Resource::ProjectWebHook.setup(session: session, merge_requests: true) do |webhook, smocker|
          create(:merge_request, project: webhook.project)

          expect_web_hook_single_event_success(webhook, smocker, type: 'merge_request')
        end
      end

      it 'sends a wiki page event', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349722' do
        Resource::ProjectWebHook.setup(session: session, wiki_page: true) do |webhook, smocker|
          create(:project_wiki_page, project: webhook.project)

          expect_web_hook_single_event_success(webhook, smocker, type: 'wiki_page')
        end
      end

      it 'sends an issues and note event',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349723' do
        Resource::ProjectWebHook.setup(session: session, issues: true, note: true) do |webhook, smocker|
          issue = create(:issue, project: webhook.project)

          create(:issue_note, project: issue.project, issue: issue)

          expect { smocker.events(session).size }.to eventually_eq(2)
                                                .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have 2 events, got: #{smocker.stringified_history(session)}" }

          events = smocker.events(session)

          aggregate_failures do
            expect(events).to include(
              a_hash_including(object_kind: 'note'),
              a_hash_including(object_kind: 'issue')
            )
          end
        end
      end

      it 'sends a tag event',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383577' do
        Resource::ProjectWebHook.setup(session: session, tag_push: true) do |webhook, smocker|
          project_push = Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          create(:tag, project: project_push.project, ref: project_push.branch_name, name: tag_name)

          expect_web_hook_single_event_success(webhook, smocker, type: 'tag_push')
        end
      end

      context 'when hook fails' do
        let(:fail_mock) do
          <<~YAML
            - request:
                method: POST
                path: /default
              response:
                status: 404
                headers:
                  Content-Type: text/plain
                body: 'webhook failed'
          YAML
        end

        let(:hook_trigger_times) { 5 }
        let(:disabled_after) { 4 }

        before do
          Runtime::Feature.enable(:auto_disabling_web_hooks)
        end

        it 'hook is auto-disabled',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/389595', quarantine: {
            type: :flaky,
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/431976'
          } do
          Resource::ProjectWebHook.setup(fail_mock, session: session, issues: true) do |webhook, smocker|
            hook_trigger_times.times do
              create(:issue, project: webhook.project)

              # using sleep to give rate limiter a chance to activate.
              sleep 0.5
            end

            expect { smocker.events(session).size }.to eventually_eq(disabled_after)
                                                  .within(max_duration: 30, sleep_interval: 2),
              -> { "Should have #{disabled_after} events, got: #{smocker.events(session).size}" }

            webhook.reload!

            expect(webhook.alert_status).to eql('disabled')
          end
        end
      end
    end

    private

    def expect_web_hook_single_event_success(webhook, smocker, type:)
      expect { smocker.events(session).size }.to eventually_eq(1)
                                                    .within(max_duration: 30, sleep_interval: 2),
        -> { "Should have 1 events, got: #{smocker.stringified_history(session)}" }

      event = smocker.events(session).first

      aggregate_failures do
        expect(event).to match(a_hash_including(
          object_kind: type,
          project: a_hash_including(name: webhook.project.name)
        ))
      end
    end

    def toggle_local_requests(on)
      Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: on)
    end
  end
end
