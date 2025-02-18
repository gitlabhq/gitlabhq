# frozen_string_literal: true

module Gitlab
  module GitalyClient
    # This module is responsible for collecting feature flag actors in Gitaly Client. Unlike normal feature flags used
    # in Gitlab development, feature flags passed to Gitaly are pre-evaluated at Rails side before being passed to
    # Gitaly. As a result, we need to collect all possible actors for the evaluation before issue any RPC. At this
    # layer, the only parameter we have is raw repository. We need to infer other actors from the repository. Adding
    # extra SQL queries before any RPC are not good for the performance. We applied some quirky optimizations here to
    # avoid issuing SQL queries. However, in some less common code paths, a couple of queries are expected.
    module WithFeatureFlagActors
      include Gitlab::Utils::StrongMemoize

      attr_accessor :repository_actor

      # gitaly_client_call performs Gitaly calls including collected feature flag actors. The actors are retrieved
      # from repository actor and memoized. The service must set `self.repository_actor = a_repository` beforehand.
      def gitaly_client_call(...)
        unless repository_actor
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            Feature::InvalidFeatureFlagError.new("gitaly_client_call called without setting repository_actor")
          )
        end

        GitalyClient.with_feature_flag_actors(
          repository: repository_actor,
          user: user_actor,
          project: project_actor,
          group: group_actor
        ) do
          GitalyClient.call(...)
        end
      end

      # gitaly_feature_flag_actors returns a hash of actors implied from input repository.
      def gitaly_feature_flag_actors(repository)
        container = find_repository_container(repository)
        {
          repository: repository,
          user: Feature::Gitaly.user_actor,
          project: Feature::Gitaly.project_actor(container),
          group: Feature::Gitaly.group_actor(container)
        }
      end

      # Use actor here means the user who originally perform the action. It is collected from ApplicationContext. As
      # this information is widely propagated in all entry points, User actor should be available everywhere, even in
      # background jobs.
      def user_actor
        strong_memoize(:user_actor) do
          Feature::Gitaly.user_actor
        end
      end

      # TODO: replace this project actor by Repo actor
      def project_actor
        strong_memoize(:project_actor) do
          Feature::Gitaly.project_actor(repository_container)
        end
      end

      def group_actor
        strong_memoize(:group_actor) do
          Feature::Gitaly.group_actor(repository_container)
        end
      end

      private

      def repository_container
        strong_memoize(:repository_container) do
          find_repository_container(repository_actor)
        end
      end

      def find_repository_container(repository)
        return if repository&.gl_repository.blank?

        if repository.container.nil?
          begin
            identifier = Gitlab::Repositories::Identifier.parse(repository.gl_repository)
            identifier.container
          rescue Gitlab::Repositories::Identifier::InvalidIdentifier
            nil
          end
        else
          repository.container
        end
      end
    end
  end
end

Gitlab::GitalyClient::WithFeatureFlagActors.prepend_mod_with('Gitlab::GitalyClient::WithFeatureFlagActors')
