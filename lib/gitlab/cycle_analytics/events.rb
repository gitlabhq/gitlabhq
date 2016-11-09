module Gitlab
  module CycleAnalytics
    class Events
      include ActionView::Helpers::DateHelper

      def initialize(project:, options:)
        @project = project
        @fetcher = EventsFetcher.new(project: project, options: options)
      end

      def issue_events
        @fetcher.fetch(stage: :issue).each { |event| parse_event(event) }
      end

      def plan_events
        @fetcher.fetch(stage: :plan).each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          commit = first_time_reference_commit(event.delete('commits'), event)
          event['title'] = commit.title
          event['url'] = Gitlab::LightUrlBuilder.build(entity: :commit, project: @project, id: commit.id)
          event['sha'] = commit.short_id
          event['author_name'] = commit.author.name
          event['author_profile_url'] = Gitlab::LightUrlBuilder.build(entity: :user, id: commit.author.username)
          event['author_avatar_url'] = Gitlab::LightUrlBuilder.build(entity: :user_avatar, id: commit.author.id)
        end
      end

      def code_events
        @fetcher.fetch(stage: :code).each { |event| parse_event(event, entity: :merge_request) }
      end

      def test_events
        @fetcher.fetch(stage: :test).each do |event|
          parse_build_event(event)
        end
      end

      def review_events
        @fetcher.fetch(stage: :review).each { |event| parse_event(event) }
      end

      def staging_events
        @fetcher.fetch(stage: :staging).each do |event|
          parse_build_event(event)
        end
      end

      def production_events
        @fetcher.fetch(stage: :production).each { |event| parse_event(event) }
      end

      private

      def parse_event(event, entity: :issue)
        event['url'] = Gitlab::LightUrlBuilder.build(entity: entity, project: @project, id: event['iid'])
        event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
        event['created_at'] = interval_in_words(event['created_at'])
        event['author_profile_url'] = Gitlab::LightUrlBuilder.build(entity: :user, id: event['author_username'])
        event['author_avatar_url'] = Gitlab::LightUrlBuilder.build(entity: :user_avatar, id: event['author_id'])

        event.except!('author_id', 'author_username')
      end

      def parse_build_event(event)
        build = ::Ci::Build.find(event['id'])
        event['name'] = build.name
        event['url'] = Gitlab::LightUrlBuilder.build(entity: :build, project: @project, id: build.id)
        event['branch'] = build.ref
        event['branch_url'] = Gitlab::LightUrlBuilder.build(entity: :branch, project: @project, id: build.ref)
        event['sha'] = build.short_sha
        event['commit_url'] = Gitlab::LightUrlBuilder.build(entity: :commit, project: @project, id: build.sha)
        event['date'] = build.started_at
        event['total_time'] = build.duration
        event['author_name'] = build.author.try(:name)
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
