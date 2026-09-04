# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', feature_category: :importers do
    describe(
      'WebHooks integration',
      :requires_admin,
      :integrations,
      :orchestrated,
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

      # Live Time values are normalized to ISO 8601 with millisecond precision on
      # delivery; values the payload builder pre-stringifies are delivered verbatim.
      let(:normalized_timestamp) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z/ }
      let(:commit_timestamp) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\z/ }

      it 'sends a push event' do
        Resource::ProjectWebHook.setup(session: session, push: true) do |webhook, smocker|
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          expect_web_hook_single_event_success(webhook, smocker, type: 'push')

          commits = smocker.events(session).first[:commits]
          aggregate_failures do
            expect(commits).not_to be_empty
            expect(commits).to all(match(a_hash_including(timestamp: match(commit_timestamp))))
          end
        end
      end

      it 'sends a merge request event' do
        Resource::ProjectWebHook.setup(session: session, merge_requests: true) do |webhook, smocker|
          create(:merge_request, project: webhook.project)

          # MR creation can trigger multiple webhook events (open + merge status update)
          expect { smocker.events(session).size >= 1 }.to eventually_be_truthy
            .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have at least 1 event, got: #{smocker.stringified_history(session)}" }

          expect(smocker.events(session)).to include(
            a_hash_including(
              object_kind: 'merge_request',
              project: a_hash_including(name: webhook.project.name),
              object_attributes: a_hash_including(
                created_at: match(normalized_timestamp),
                updated_at: match(normalized_timestamp)
              )
            )
          )
        end
      end

      it 'sends a wiki page event' do
        Resource::ProjectWebHook.setup(session: session, wiki_page: true) do |webhook, smocker|
          create(:project_wiki_page, project: webhook.project)

          expect_web_hook_single_event_success(webhook, smocker, type: 'wiki_page')
        end
      end

      it 'sends an issues and note event' do
        Resource::ProjectWebHook.setup(session: session, issues: true, note: true) do |webhook, smocker|
          issue = create(:issue, project: webhook.project)

          create(:issue_note, project: issue.project, issue: issue)

          expect { smocker.events(session).size }.to eventually_eq(2)
                                                .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have 2 events, got: #{smocker.stringified_history(session)}" }

          events = smocker.events(session)

          aggregate_failures do
            expect(events).to include(
              a_hash_including(
                object_kind: 'note',
                object_attributes: a_hash_including(created_at: match(normalized_timestamp)),
                issue: a_hash_including(created_at: match(normalized_timestamp))
              ),
              a_hash_including(
                object_kind: 'issue',
                object_attributes: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                )
              )
            )
          end
        end
      end

      it 'sends a tag event' do
        Resource::ProjectWebHook.setup(session: session, tag_push: true) do |webhook, smocker|
          project_push = Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          create(:tag, project: project_push.project, ref: project_push.branch_name, name: tag_name)

          expect_web_hook_single_event_success(webhook, smocker, type: 'tag_push')
        end
      end

      it 'sends a release event' do
        Resource::ProjectWebHook.setup(session: session, releases: true) do |webhook, smocker|
          project_push = Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          create(:release, project: webhook.project, tag_name: tag_name, ref: project_push.branch_name)

          expect_web_hook_single_event_success(webhook, smocker, type: 'release')

          expect(smocker.events(session).first).to match(a_hash_including(
            created_at: match(normalized_timestamp),
            released_at: match(normalized_timestamp),
            commit: a_hash_including(timestamp: match(commit_timestamp))
          ))
        end
      end

      context 'with a custom webhook template' do
        let(:template) do
          '{"kind":"{{object_kind}}","created_at":"{{object_attributes.created_at}}"}'
        end

        # Rendering to invalid JSON aborts delivery before the request is sent, so a
        # regression shows up as zero events rather than a malformed body.
        it 'delivers the rendered template with an ISO 8601 timestamp' do
          Resource::ProjectWebHook.setup(session: session, issues: true,
            custom_webhook_template: template) do |webhook, smocker|
            create(:issue, project: webhook.project)

            expect { smocker.events(session).size }.to eventually_eq(1)
                                                   .within(max_duration: 30, sleep_interval: 2),
              -> { "Should have 1 event, got: #{smocker.stringified_history(session)}" }

            expect(smocker.events(session).first).to match(a_hash_including(
              kind: 'issue',
              created_at: match(normalized_timestamp)
            ))
          end
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

        before do
          Runtime::Feature.enable(:auto_disabling_web_hooks)
        end

        it 'hook is temporarily disabled after repeated failures' do
          Resource::ProjectWebHook.setup(fail_mock, session: session, issues: true) do |webhook, smocker|
            hook_trigger_times.times do |_i|
              create(:issue, project: webhook.project)
              sleep 1
            end

            expect { smocker.events(session).size >= 4 }.to eventually_be_truthy
              .within(max_duration: 30, sleep_interval: 2),
              -> { "Should have at least 4 events, got: #{smocker.events(session).size}" }

            webhook.reload!

            expect { webhook.reload!.alert_status }.to eventually_eq('temporarily_disabled')
              .within(max_duration: 30, sleep_interval: 2),
              -> { "Expected temporarily_disabled, got: #{webhook.alert_status}" }
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
