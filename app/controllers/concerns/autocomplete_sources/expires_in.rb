# frozen_string_literal: true

module AutocompleteSources
  module ExpiresIn
    extend ActiveSupport::Concern

    AUTOCOMPLETE_EXPIRES_IN = 3.minutes
    AUTOCOMPLETE_CACHED_ACTIONS = [:members, :labels].freeze

    included do
      before_action :set_expires_in, only: AUTOCOMPLETE_CACHED_ACTIONS
    end

    private

    def set_expires_in
      expires_in AUTOCOMPLETE_EXPIRES_IN
    end
  end
end
