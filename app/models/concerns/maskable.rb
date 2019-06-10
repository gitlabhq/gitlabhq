# frozen_string_literal: true

module Maskable
  extend ActiveSupport::Concern

  # * Single line
  # * No escape characters
  # * No variables
  # * No spaces
  # * Minimal length of 8 characters from the Base64 alphabets (RFC4648)
  # * Absolutely no fun is allowed
  REGEX = /\A[a-zA-Z0-9_+=\/-]{8,}\z/.freeze

  included do
    validates :masked, inclusion: { in: [true, false] }
    validates :value, format: { with: REGEX }, if: :masked?
  end

  def to_runner_variable
    super.merge(masked: masked?)
  end
end
