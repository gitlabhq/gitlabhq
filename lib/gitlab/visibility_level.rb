# Gitlab::VisibilityLevel module
#
# Define allowed public modes that can be used for
# GitLab projects to determine project public mode
#
module Gitlab
  module VisibilityLevel
    PRIVATE  = 0
    INTERNAL = 10
    PUBLIC   = 20

    class << self
      def values
        options.values
      end

      def options
        {
          'Private'  => PRIVATE,
          'Internal' => INTERNAL,
          'Public'   => PUBLIC
        }
      end

      def allowed_for?(user, level)
        user.is_admin? || !Gitlab.config.gitlab.restricted_visibility_levels.include?(level)
      end
    end

    module ClassMethods
      def public_only
        where(visibility_level: PUBLIC)
      end

      def public_or_internal_only(user)
        where("visibility_level IN (:levels)", levels: user ? [ INTERNAL, PUBLIC ] : [ PUBLIC ])
      end
    end

    def private?
      visibility_level == PRIVATE
    end

    def internal?
      visibility_level == INTERNAL
    end

    def public?
      visibility_level == PUBLIC
    end
  end
end
