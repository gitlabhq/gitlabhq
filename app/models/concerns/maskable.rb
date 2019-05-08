# frozen_string_literal: true

module Maskable
  extend ActiveSupport::Concern

  # * Single line
  # * No escape characters
  # * No variables
  # * No spaces
  # * Minimal length of 8 characters
  # * Absolutely no fun is allowed
  REGEX = /\A\w{8,}\z/.freeze

  included do
    validates :masked, inclusion: { in: [true, false] }
    validates :value, format: { with: REGEX }, if: :masked?
  end

  def to_runner_variable
    super.merge(masked: masked?)
  end
end
