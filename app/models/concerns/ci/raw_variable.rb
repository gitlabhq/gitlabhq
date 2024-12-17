# frozen_string_literal: true

module Ci
  module RawVariable
    extend ActiveSupport::Concern

    included do
      validates :raw, inclusion: { in: [true, false] }
    end

    private

    def uncached_hash_variable
      super.merge(raw: raw?)
    end
  end
end
