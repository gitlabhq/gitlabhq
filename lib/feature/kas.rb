# frozen_string_literal: true

module Feature
  class Kas
    PREFIX = "kas_"

    class << self
      def enabled_for_any?(feature_flag, *actors)
        return false unless Feature::FlipperFeature.table_exists?

        actors = actors.compact
        # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- this is a helper function and we need a variable argument here
        # rubocop:disable Gitlab/FeatureFlagWithoutActor -- we explicitly don't want an actor here
        return Feature.enabled?(feature_flag, type: :undefined, default_enabled_if_undefined: false) if actors.empty?

        # rubocop:enable Gitlab/FeatureFlagWithoutActor

        actors.any? do |actor|
          Feature.enabled?(feature_flag, actor, type: :undefined, default_enabled_if_undefined: false)
        end
        # rubocop:enable Gitlab/FeatureFlagKeyDynamic
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
        false
      end

      def server_feature_flags_for_grpc_request(user: nil, project: nil, group: nil)
        server_feature_flags(
          ->(f) { "kas-feature-#{f.delete_prefix(PREFIX).tr('_', '-')}" },
          user: user,
          project: project,
          group: group
        )
      end

      def server_feature_flags_for_http_response(user: nil, project: nil, group: nil)
        server_feature_flags(
          ->(f) { f.delete_prefix(PREFIX) },
          user: user,
          project: project,
          group: group
        )
      end

      def user_actor(user = nil)
        return ::User.actor_from_id(user.id) if user.is_a?(::User)

        user_id = Gitlab::ApplicationContext.current_context_attribute(Labkit::Fields::GL_USER_ID)
        ::User.actor_from_id(user_id) if user_id
      end

      def project_actor(container)
        return unless container

        return ::Project.actor_from_id(container.project.id) if container.is_a?(::Clusters::Agent)

        ::Project.actor_from_id(container.id) if container.is_a?(::Project)
      end

      def group_actor(container)
        return unless container

        return ::Group.actor_from_id(container.id) if container.is_a?(::Group)
        return ::Group.actor_from_id(container.project.namespace_id) if container.is_a?(::Clusters::Agent)

        ::Group.actor_from_id(container.namespace_id) if container.is_a?(::Project)
      end

      private

      def server_feature_flags(key_transform, user: nil, project: nil, group: nil)
        # We need to check that both the DB connection and table exists
        return {} unless FlipperFeature.database.cached_table_exists?

        # The order of actors here is significant.
        # Percentage-based actor selection may not work as expected if this order changes.
        actors = [user, project, group].compact

        Feature.persisted_names
          .select { |f| f.start_with?(PREFIX) }
          .to_h do |f|
            key = key_transform ? key_transform.call(f) : f
            [key, enabled_for_any?(f, *actors).to_s]
          end
      end
    end
  end
end
