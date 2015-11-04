# Gitlab::VisibilityLevel module
#
# Define allowed public modes that can be used for
# GitLab projects to determine project public mode
#
module Gitlab
  module VisibilityLevel
    extend CurrentSettings

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
        user.is_admin? || allowed_level?(level.to_i)
      end

      # Return true if the specified level is allowed for the current user.
      # Level should be a numeric value, e.g. `20`.
      def allowed_level?(level)
        valid_level?(level) && non_restricted_level?(level)
      end

      def non_restricted_level?(level)
        restricted_levels = current_application_settings.restricted_visibility_levels

        if restricted_levels.nil?
          true
        else
          !restricted_levels.include?(level)
        end
      end

      def valid_level?(level)
        options.has_value?(level)
      end

      def allowed_fork_levels(origin_level)
        [PRIVATE, INTERNAL, PUBLIC].select{ |level| level <= origin_level }
      end

      def level_name(level)
        level_name = 'Unknown'
        options.each do |name, lvl|
          level_name = name if lvl == level.to_i
        end

        level_name
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
