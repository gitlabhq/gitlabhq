module Gitlab
  module CycleAnalytics
    class Events
      def initialize(project:, options:)
        @project = project
        @fetcher = EventsFetcher.new(project: project, options: options)
      end

      def issue_events
        @fetcher.fetch(stage: :issue).map { |event| serialize_event(event) }
      end

      def plan_events
        @fetcher.fetch(stage: :plan).map do |event|
          st_commit = first_time_reference_commit(event.delete('commits'), event)

          next unless st_commit

          serialize_commit(event, st_commit)
        end
      end

      def code_events
        @fetcher.fetch(stage: :code).map { |event| serialize_event(event, entity: :merge_request) }
      end

      def test_events
        @fetcher.fetch(stage: :test).map { |event| serialize_build_event(event) }
      end

      def review_events
        @fetcher.fetch(stage: :review).map { |event| serialize_event(event, entity: :merge_request) }
      end

      def staging_events
        @fetcher.fetch(stage: :staging).map { |event| serialize_build_event(event) }
      end

      def production_events
        @fetcher.fetch(stage: :production).map { |event| serialize_event(event) }
      end

      private

      def serialize_event(event, entity: :issue)
        event['author'] = User.find(event.delete('author_id'))

        AnalyticsGenericSerializer.new(project: @project, entity: entity).represent(event).as_json
      end

      def serialize_build_event(event)
        build = ::Ci::Build.find(event['id'])

        AnalyticsBuildSerializer.new.represent(build).as_json
      end

      def first_time_reference_commit(commits, event)
        YAML.load(commits).find do |commit|
          next unless commit[:committed_date] && event['first_mentioned_in_commit_at']

          commit[:committed_date].to_i == DateTime.parse(event['first_mentioned_in_commit_at'].to_s).to_i
        end
      end

      def serialize_commit(event, st_commit)
        commit = Commit.new(Gitlab::Git::Commit.new(st_commit), @project)

        AnalyticsCommitSerializer.new(project: @project, total_time: event['total_time']).represent(commit).as_json
      end

      def interval_in_words(diff)
        "#{distance_of_time_in_words(diff.to_f)} ago"
      end
    end
  end
end
