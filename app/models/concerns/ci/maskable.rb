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
    REGEX = %r{\A[a-zA-Z0-9_+=/@:.~-]{8,}\z}
    # * Single line
    # * No spaces
    # * Minimal length of 8 characters
    # * Some fun is allowed
    MASK_AND_RAW_REGEX = %r{\A\S{8,}\z}

    included do
      validates :masked, inclusion: { in: [true, false] }
      validates :value, format: { with: REGEX }, if: :masked_and_expanded?
      validates :value, format: { with: MASK_AND_RAW_REGEX }, if: :masked_and_raw?
    end

    def masked_and_raw?
      return false unless self.class.method_defined?(:raw)

      masked? && raw?
    end

    def masked_and_expanded?
      return masked? unless self.class.method_defined?(:raw)

      masked? && !raw?
    end

    def to_hash_variable
      super.merge(masked: masked?)
    end
  end
end
