# frozen_string_literal: true

module AutocompleteSources
  module ExpiresIn
    extend ActiveSupport::Concern

    AUTOCOMPLETE_EXPIRES_IN = 3.minutes
    AUTOCOMPLETE_CACHED_ACTIONS = [:members, :commands, :labels].freeze

    included do
      before_action :set_expires_in, only: AUTOCOMPLETE_CACHED_ACTIONS
    end

    private

    def set_expires_in
      case action_name.to_sym
      when :members
        expires_in AUTOCOMPLETE_EXPIRES_IN if Feature.enabled?(:cache_autocomplete_sources_members, current_user)
      when :commands
        expires_in AUTOCOMPLETE_EXPIRES_IN if Feature.enabled?(:cache_autocomplete_sources_commands, current_user)
      when :labels
        expires_in AUTOCOMPLETE_EXPIRES_IN if Feature.enabled?(:cache_autocomplete_sources_labels, current_user)
      end
    end
  end
end
