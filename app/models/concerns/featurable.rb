# frozen_string_literal: true

# == Featurable concern
#
# This concern adds features (tools) functionality to Project and Group
# To enable features you need to call `set_available_features`
#
# Example:
#
# class ProjectFeature
#   include Featurable
#   set_available_features %i(wiki merge_request)

module Featurable
  extend ActiveSupport::Concern

  # Can be enabled only for members, everyone or disabled
  # Access control is made only for non private containers.
  #
  # Permission levels:
  #
  # Disabled: not enabled for anyone
  # Private:  enabled only for team members
  # Enabled:  enabled for everyone able to access the project
  # Public:   enabled for everyone (only allowed for pages)
  DISABLED = 0
  PRIVATE  = 10
  ENABLED  = 20
  PUBLIC   = 30

  STRING_OPTIONS = HashWithIndifferentAccess.new({
    'disabled' => DISABLED,
    'private' => PRIVATE,
    'enabled' => ENABLED,
    'public' => PUBLIC
  }).freeze

  class_methods do
    def set_available_features(available_features = [])
      @available_features ||= []
      @available_features += available_features

      class_eval do
        available_features.each do |feature|
          define_method("#{feature}_enabled?") do
            public_send("#{feature}_access_level") > DISABLED # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end

    def available_features
      @available_features || []
    end

    def access_level_attribute(feature)
      feature = ensure_feature!(feature)

      "#{feature}_access_level".to_sym
    end

    def quoted_access_level_column(feature)
      attribute = connection.quote_column_name(access_level_attribute(feature))
      table = connection.quote_table_name(table_name)

      "#{table}.#{attribute}"
    end

    def access_level_from_str(level)
      STRING_OPTIONS.fetch(level)
    end

    def str_from_access_level(level)
      STRING_OPTIONS.key(level)
    end

    def required_minimum_access_level(feature)
      ensure_feature!(feature)

      Gitlab::Access::GUEST
    end

    def ensure_feature!(feature)
      feature = feature.model_name.plural if feature.respond_to?(:model_name)
      feature = feature.to_sym
      raise ArgumentError, "invalid feature: #{feature}" unless available_features.include?(feature)

      feature
    end
  end

  included do
    validate :allowed_access_levels
  end

  def access_level(feature)
    public_send(self.class.access_level_attribute(feature)) # rubocop:disable GitlabSecurity/PublicSend
  end

  def feature_available?(feature, user = nil)
    has_permission?(user, feature)
  end

  def string_access_level(feature)
    self.class.str_from_access_level(access_level(feature))
  end

  private

  def allowed_access_levels
    validator = ->(field) do
      level = public_send(field) || ENABLED # rubocop:disable GitlabSecurity/PublicSend
      not_allowed = level > ENABLED
      self.errors.add(field, "cannot have public visibility level") if not_allowed
    end

    (self.class.available_features - feature_validation_exclusion).each { |f| validator.call("#{f}_access_level") }
  end

  # Features that we should exclude from the validation
  def feature_validation_exclusion
    []
  end

  def has_permission?(user, feature)
    case access_level(feature)
    when DISABLED
      false
    when PRIVATE
      member?(user, feature)
    when ENABLED
      true
    when PUBLIC
      true
    else
      true
    end
  end

  def member?(user, feature)
    return false unless user
    return true if user.can_read_all_resources?

    resource_member?(user, feature)
  end

  def resource_member?(user, feature)
    raise NotImplementedError
  end
end
