# frozen_string_literal: true

module Ci
  module Maskable
    extend ActiveSupport::Concern

    # * Single line
    # * No escape characters
    # * No variables
    # * No spaces
    # * Minimal length of 8 characters
    # * Characters must be from the Base64 alphabet (RFC4648) with the addition of '@', ':', '.', and '~'
    # * Absolutely no fun is allowed
    REGEX = %r{\A[a-zA-Z0-9_+=/@:.~-]{8,}\z}.freeze

    included do
      validates :masked, inclusion: { in: [true, false] }
      validates :value, format: { with: REGEX }, if: :masked?
    end

    def to_runner_variable
      super.merge(masked: masked?)
    end
  end
end
