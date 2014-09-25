# Gitlab::VisibilityLevel module
#
# Define allowed public modes that can be used for
# GitLab projects to determine project public mode
#
module Gitlab
  module VisibilityLevel
    PRIVATE  = 0 unless const_defined?(:PRIVATE)
    INTERNAL = 10 unless const_defined?(:INTERNAL)
    PUBLIC   = 20 unless const_defined?(:PUBLIC)

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
        user.is_admin? || allowed_level?(level)
      end

      # Level can be a string `"public"` or a value `20`, first check if valid,
      # then check if the corresponding string appears in the config
      def allowed_level?(level)
        if options.has_key?(level.to_s)
          non_restricted_level?(level)
        elsif options.has_value?(level.to_i)
          non_restricted_level?(options.key(level.to_i).downcase)
        end
      end

      def non_restricted_level?(level)
        ! Gitlab.config.gitlab.restricted_visibility_levels.include?(level)
      end
    end

    def private?
      visibility_level_field == PRIVATE
    end

    def internal?
      visibility_level_field == INTERNAL
    end

    def public?
      visibility_level_field == PUBLIC
    end
  end
end
