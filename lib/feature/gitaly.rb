# frozen_string_literal: true

module Feature
  class Gitaly
    PREFIX = "gitaly_"

    # Wrapper for feature flag actor to avoid unnecessarily SQL queries
    class ActorWrapper
      def initialize(klass, id)
        @klass = klass
        @id = id
      end

      def flipper_id
        "#{@klass.name}:#{@id}"
      end
    end

    class << self
      def enabled_for_any?(feature_flag, *actors)
        return false unless Feature::FlipperFeature.table_exists?

        actors = actors.compact
        return Feature.enabled?(feature_flag, type: :undefined, default_enabled_if_undefined: false) if actors.empty?

        actors.any? do |actor|
          Feature.enabled?(feature_flag, actor, type: :undefined, default_enabled_if_undefined: false)
        end
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
        false
      end

      def server_feature_flags(repository: nil, user: nil, project: nil, group: nil)
        # We need to check that both the DB connection and table exists
        return {} unless FlipperFeature.database.cached_table_exists?

        # The order of actors here is significant. Percentage-based actor selection may not work as expected if this
        # order changes. We want repository actor to take highest precedence.
        actors = [repository, user, project, group].compact

        Feature.persisted_names
          .select { |f| f.start_with?(PREFIX) }
          .to_h do |f|
            ["gitaly-feature-#{f.delete_prefix(PREFIX).tr('_', '-')}", enabled_for_any?(f, *actors).to_s]
          end
      end

      def user_actor(user = nil)
        return ::Feature::Gitaly::ActorWrapper.new(::User, user.id) if user.is_a?(::User)

        user_id = Gitlab::ApplicationContext.current_context_attribute(:user_id)
        ::Feature::Gitaly::ActorWrapper.new(::User, user_id) if user_id
      end

      def project_actor(container)
        return actor_wrapper(::Project, container.id) if container.is_a?(::Project)
        return actor_wrapper(::Project, container.project.id) if container.is_a?(DesignManagement::Repository)
      end

      def group_actor(container)
        return actor_wrapper(::Group, container.namespace_id) if container.is_a?(::Project)
        return actor_wrapper(::Group, container.project.namespace_id) if container.is_a?(DesignManagement::Repository)
      end

      private

      def actor_wrapper(actor_type, id)
        ::Feature::Gitaly::ActorWrapper.new(actor_type, id)
      end
    end
  end
end
