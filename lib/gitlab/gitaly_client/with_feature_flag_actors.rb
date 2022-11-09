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

      def gitaly_client_call(*args, **kargs)
        if Feature.enabled?(:actors_aware_gitaly_calls)
          # The order of actors here is significant. Percentage-based actor selection may not work as expected if this
          # order changes.
          GitalyClient.with_feature_flag_actors(
            repository: repository_actor,
            user: user_actor,
            project: project_actor,
            group: group_actor
          ) do
            GitalyClient.call(*args, **kargs)
          end
        else
          GitalyClient.call(*args, **kargs)
        end
      end

      def repository_container
        strong_memoize(:repository_container) do
          next if repository_actor&.gl_repository.blank?

          if repository_actor.container.nil?
            identifier = Gitlab::GlRepository::Identifier.parse(repository_actor.gl_repository)
            identifier.container
          else
            repository_actor.container
          end
        end
      end
    end
  end
end

Gitlab::GitalyClient::WithFeatureFlagActors.prepend_mod_with('Gitlab::GitalyClient::WithFeatureFlagActors')
