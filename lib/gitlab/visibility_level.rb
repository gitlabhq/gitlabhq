# frozen_string_literal: true

# Gitlab::VisibilityLevel module
#
# Define allowed public modes that can be used for
# GitLab projects to determine project public mode
#
module Gitlab
  module VisibilityLevel
    extend ActiveSupport::Concern

    included do
      scope :public_only,               -> { where(visibility_level: PUBLIC) }
      scope :public_and_internal_only,  -> { where(visibility_level: [PUBLIC, INTERNAL] ) }
      scope :non_public_only,           -> { where.not(visibility_level: PUBLIC) }

      scope :public_to_user, -> (user = nil) do
        where(visibility_level: VisibilityLevel.levels_for_user(user))
      end
    end

    PRIVATE  = 0 unless const_defined?(:PRIVATE)
    INTERNAL = 10 unless const_defined?(:INTERNAL)
    PUBLIC   = 20 unless const_defined?(:PUBLIC)

    class << self
      delegate :values, to: :options

      def levels_for_user(user = nil)
        return [PUBLIC] unless user

        if user.can_read_all_resources?
          [PRIVATE, INTERNAL, PUBLIC]
        elsif user.external?
          [PUBLIC]
        else
          [INTERNAL, PUBLIC]
        end
      end

      def string_values
        string_options.keys
      end

      def options
        {
          s_('VisibilityLevel|Private')  => PRIVATE,
          s_('VisibilityLevel|Internal') => INTERNAL,
          s_('VisibilityLevel|Public')   => PUBLIC
        }
      end

      def string_options
        {
          'private'  => PRIVATE,
          'internal' => INTERNAL,
          'public'   => PUBLIC
        }
      end

      def allowed_levels
        restricted_levels = Gitlab::CurrentSettings.restricted_visibility_levels

        self.values - Array(restricted_levels)
      end

      def closest_allowed_level(target_level)
        highest_allowed_level = allowed_levels.select { |level| level <= target_level }.max

        # If all levels are restricted, fall back to PRIVATE
        highest_allowed_level || PRIVATE
      end

      def allowed_for?(user, level)
        user.admin? || allowed_level?(level.to_i)
      end

      # Level should be a numeric value, e.g. `20`
      # Return true if the specified level is allowed for the current user.
      def allowed_level?(level)
        valid_level?(level) && non_restricted_level?(level)
      end

      def non_restricted_level?(level)
        !restricted_level?(level)
      end

      def restricted_level?(level)
        restricted_levels = Gitlab::CurrentSettings.restricted_visibility_levels

        if restricted_levels.nil?
          false
        else
          restricted_levels.include?(level)
        end
      end

      def public_visibility_restricted?
        restricted_level?(PUBLIC)
      end

      def valid_level?(level)
        options.value?(level)
      end

      def level_name(level)
        options.key(level.to_i) || s_('VisibilityLevel|Unknown')
      end

      def level_value(level)
        return level.to_i if level.to_i.to_s == level.to_s && string_options.key(level.to_i)

        string_options[level] || PRIVATE
      end

      def string_level(level)
        string_options.key(level)
      end
    end

    def visibility_level_previous_changes
      previous_changes[:visibility_level]
    end

    def private?
      visibility_level_value == PRIVATE
    end

    def internal?
      visibility_level_value == INTERNAL
    end

    def public?
      visibility_level_value == PUBLIC
    end

    def visibility_level_value
      self[visibility_level_field]
    end

    def visibility
      Gitlab::VisibilityLevel.string_level(visibility_level_value)
    end

    def visibility=(level)
      self[visibility_level_field] = Gitlab::VisibilityLevel.level_value(level)
    end

    def visibility_attribute_present?(attributes)
      visibility_level_attributes.each do |attr|
        return true if attributes[attr].present?
      end

      false
    end

    def visibility_level_attributes
      [visibility_level_field, visibility_level_field.to_s,
       :visibility, 'visibility']
    end
  end
end
