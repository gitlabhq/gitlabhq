module Gitlab
  module CycleAnalytics
    class Events
      include ActionView::Helpers::DateHelper

      def initialize(project:, from:)
        @project = project
        @from = from
        @fetcher = EventsFetcher.new(project: project, from: from)
      end

      # TODO: backend pagination - specially for commits, etc...

      def issue_events
        # TODO figure out what the frontend needs for displaying the avatar
        @fetcher.fetch(stage: :issue).each { |event| parse_event(event) }
      end

      def plan_events
        @fetcher.fetch(stage: :plan).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          commits = event.delete('commits')
          event['commit'] = first_time_reference_commit(commits, event)
        end
      end

      def code_events
        @fetcher.fetch(stage: :code).each { |event| parse_event(event) }
      end

      def test_events
        @fetcher.fetch(stage: :test).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          event['pipeline'] = ::Ci::Pipeline.find_by_id(event['ci_commit_id']) # we may not have a pipeline
        end
      end

      def review_events
        @fetcher.fetch(stage: :review).each { |event| parse_event(event) }
      end

      def staging_events
        @fetcher.fetch(stage: :staging).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          event['pipeline'] = ::Ci::Pipeline.find_by_id(event['ci_commit_id']) # we may not have a pipeline
        end
      end

      private

      def parse_event(event)
        event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
        event['created_at'] = interval_in_words(event['created_at'])
      end

      def first_time_reference_commit(commits, event)
        st_commit = YAML.load(commits).detect do |commit|
          commit['created_at'] == event['first_mentioned_in_commit_at']
        end

        Commit.new(Gitlab::Git::Commit.new(st_commit), @project)
      end

      def interval_in_words(diff)
        "#{distance_of_time_in_words(diff.to_f)} ago"
      end
    end
  end
end
