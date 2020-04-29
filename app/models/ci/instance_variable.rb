# frozen_string_literal: true

module Ci
  class InstanceVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    include Ci::NewHasVariable
    include Ci::Maskable

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
  end
end
