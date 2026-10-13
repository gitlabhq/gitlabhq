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
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }

      # Live Time values are normalized to ISO 8601 with millisecond precision on
      # delivery; values the payload builder pre-stringifies are delivered verbatim.
      let(:normalized_timestamp) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z/ }
      let(:commit_timestamp) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\z/ }
      # Deployment lifecycle timestamps round-trip through Sidekiq as zoned strings
      # (Deployment#serialize_params_for_sidekiq! + String#to_time), so they render
      # with a numeric offset instead of Z.
      let(:offset_normalized_timestamp) { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2}\z/ }
      # Pipeline builds[] are wrapped in Gitlab::Lazy, which Gitlab::WebHooks.normalize_dates
      # does not unwrap, so their timestamps still arrive as Ruby Time#to_s.
      let(:legacy_timestamp) { /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (?:UTC|[+-]\d{4})\z/ }

      it 'sends push and commit note events' do
        Resource::ProjectWebHook.setup(session: session, push: true, note: true) do |webhook, smocker|
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          expect_web_hook_single_event_success(webhook, smocker, type: 'push')

          push_event = smocker.events(session).first
          webhook.project.comment_on_commit(sha: push_event[:checkout_sha], note: 'commit comment')

          expect { smocker.events(session).size }.to eventually_eq(2)
                                                 .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have 2 events, got: #{smocker.stringified_history(session)}" }

          aggregate_failures do
            expect(push_event[:commits]).not_to be_empty
            expect(push_event[:commits]).to all(match(a_hash_including(timestamp: match(commit_timestamp))))
            expect(smocker.events(session)).to include(
              a_hash_including(
                object_kind: 'note',
                object_attributes: a_hash_including(
                  noteable_type: 'Commit',
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                )
              )
            )
          end
        end
      end

      it 'sends merge request and note events' do
        Resource::ProjectWebHook.setup(session: session, merge_requests: true, note: true) do |webhook, smocker|
          label = create(:project_label, project: webhook.project)
          merge_request = create(:merge_request, project: webhook.project, labels: [label.title])

          # MergeRequests::AfterCreateService sets prepared_at before firing the 'open' hook, and an
          # 'update' hook with empty changes can follow it, so wait for content rather than a count.
          expect { smocker.events(session).any? { |event| event.dig(:object_attributes, :action) == 'open' } }
            .to eventually_be_truthy.within(max_duration: 30, sleep_interval: 2),
              -> { "Expected an open merge request event, got: #{smocker.stringified_history(session)}" }

          merge_request.add_comment(body: 'merge request comment')

          expect { smocker.events(session).any? { |event| event[:object_kind] == 'note' } }
            .to eventually_be_truthy.within(max_duration: 30, sleep_interval: 2),
              -> { "Expected a note event, got: #{smocker.stringified_history(session)}" }

          events = smocker.events(session)
          label_timestamps = a_hash_including(
            created_at: match(normalized_timestamp),
            updated_at: match(normalized_timestamp)
          )

          aggregate_failures do
            expect(events).to include(
              a_hash_including(
                object_kind: 'merge_request',
                project: a_hash_including(name: webhook.project.name),
                object_attributes: a_hash_including(
                  action: 'open',
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp),
                  actioned_at: match(normalized_timestamp),
                  prepared_at: match(normalized_timestamp),
                  labels: [label_timestamps]
                ),
                labels: [label_timestamps],
                changes: a_hash_including(
                  updated_at: a_hash_including(
                    previous: match(normalized_timestamp),
                    current: match(normalized_timestamp)
                  ),
                  prepared_at: a_hash_including(current: match(normalized_timestamp))
                )
              ),
              a_hash_including(
                object_kind: 'note',
                object_attributes: a_hash_including(
                  noteable_type: 'MergeRequest',
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                ),
                merge_request: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp),
                  last_commit: a_hash_including(timestamp: match(commit_timestamp))
                )
              )
            )
          end
        end
      end

      it 'sends a wiki page event' do
        Resource::ProjectWebHook.setup(session: session, wiki_page: true) do |webhook, smocker|
          create(:project_wiki_page, project: webhook.project)

          expect_web_hook_single_event_success(webhook, smocker, type: 'wiki_page')
        end
      end

      it 'sends issue, note, emoji, milestone and snippet note events' do
        Resource::ProjectWebHook.setup(session: session,
          issues: true, note: true, emoji: true, milestone: true) do |webhook, smocker|
          project = webhook.project
          milestone = create(:project_milestone, project: project)
          first_label = create(:project_label, project: project)
          second_label = create(:project_label, project: project)

          issue = create(:issue, project: project, labels: [first_label.title], milestone: milestone)
          note = issue.add_comment(body: 'issue comment')
          issue.award_emoji_on_note(note_id: note[:id], name: 'thumbsup')
          issue.set_labels([second_label.title])

          snippet = create(:project_snippet, project: project)
          snippet.add_comment(body: 'snippet comment')

          # milestone create, issue open, note, emoji, issue update, snippet note
          expect { smocker.events(session).size }.to eventually_eq(6)
                                                 .within(max_duration: 60, sleep_interval: 2),
            -> { "Should have 6 events, got: #{smocker.stringified_history(session)}" }

          events = smocker.events(session)
          label_timestamps = a_hash_including(
            created_at: match(normalized_timestamp),
            updated_at: match(normalized_timestamp)
          )

          aggregate_failures do
            expect(events).to include(
              a_hash_including(
                object_kind: 'milestone',
                object_attributes: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                )
              ),
              a_hash_including(
                object_kind: 'issue',
                object_attributes: a_hash_including(
                  action: 'open',
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                ),
                labels: [label_timestamps]
              ),
              a_hash_including(
                object_kind: 'issue',
                object_attributes: a_hash_including(action: 'update'),
                changes: a_hash_including(
                  updated_at: a_hash_including(
                    previous: match(normalized_timestamp),
                    current: match(normalized_timestamp)
                  ),
                  labels: a_hash_including(previous: [label_timestamps], current: [label_timestamps])
                )
              ),
              a_hash_including(
                object_kind: 'note',
                object_attributes: a_hash_including(
                  noteable_type: 'Issue',
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                ),
                issue: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                )
              ),
              a_hash_including(
                object_kind: 'emoji',
                object_attributes: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                ),
                note: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                ),
                issue: a_hash_including(
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                )
              ),
              a_hash_including(
                object_kind: 'note',
                object_attributes: a_hash_including(
                  noteable_type: 'Snippet',
                  created_at: match(normalized_timestamp),
                  updated_at: match(normalized_timestamp)
                ),
                snippet: a_hash_including(
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

      it 'sends deployment events' do
        Resource::ProjectWebHook.setup(session: session, deployment: true) do |webhook, smocker|
          project_push = Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = webhook.project
          end

          deployment = create(:deployment,
            project: webhook.project,
            environment: 'production',
            ref: project_push.branch_name,
            sha: webhook.project.commits.first[:id])
          deployment.succeed!

          # One event for the running state, one for the success transition
          expect { smocker.events(session).size }.to eventually_eq(2)
                                                 .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have 2 events, got: #{smocker.stringified_history(session)}" }

          expect(smocker.events(session)).to include(
            a_hash_including(
              object_kind: 'deployment',
              status: 'success',
              status_changed_at: match(offset_normalized_timestamp)
            )
          )
        end
      end

      it 'sends pipeline events' do
        Resource::ProjectWebHook.setup(session: session, pipeline: true) do |webhook, smocker|
          runner = create(:project_runner, project: webhook.project, name: executor, tags: [executor])

          begin
            runner.wait_until_online

            create(:commit, project: webhook.project, commit_message: 'Add .gitlab-ci.yml', actions: [
              {
                action: 'create',
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  test-webhook-pipeline:
                    tags: [#{executor}]
                    script: echo ok
                YAML
              }
            ])

            Flow::Pipeline.wait_for_pipeline_creation_via_api(project: webhook.project)
            Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: webhook.project, status: 'success')

            expect { smocker.events(session).any? { |event| event.dig(:object_attributes, :status) == 'success' } }
              .to eventually_be_truthy.within(max_duration: 60, sleep_interval: 2),
                -> { "Expected a success pipeline event, got: #{smocker.stringified_history(session)}" }

            succeeded = smocker.events(session).find do |event|
              event[:object_kind] == 'pipeline' && event.dig(:object_attributes, :status) == 'success'
            end

            aggregate_failures do
              expect(succeeded[:object_attributes]).to match(a_hash_including(
                created_at: match(normalized_timestamp),
                finished_at: match(normalized_timestamp)
              ))
              expect(succeeded[:builds]).not_to be_empty
              expect(succeeded[:builds]).to all(match(a_hash_including(
                created_at: match(legacy_timestamp),
                started_at: match(legacy_timestamp),
                finished_at: match(legacy_timestamp)
              )))
            end
          ensure
            runner.remove_via_api!
          end
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
