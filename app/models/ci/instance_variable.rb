# frozen_string_literal: true

module Ci
  class InstanceVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    extend Gitlab::ProcessMemoryCache::Helper
    include Ci::NewHasVariable
    include Ci::Maskable
    include Limitable

    self.limit_name = 'ci_instance_level_variables'
    self.limit_scope = Limitable::GLOBAL_SCOPE

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      message: "(%{value}) has already been taken"
    }

    validates :encrypted_value, length: {
      maximum: 1024,
      too_long: 'The encrypted value of the provided variable exceeds %{count} bytes. Variables over 700 characters risk exceeding the limit.'
    }

    scope :unprotected, -> { where(protected: false) }

    after_commit { self.class.invalidate_memory_cache(:ci_instance_variable_data) }

    class << self
      def all_cached
        cached_data[:all]
      end

      def unprotected_cached
        cached_data[:unprotected]
      end

      private

      def cached_data
        fetch_memory_cache(:ci_instance_variable_data) do
          all_records = unscoped.all.to_a

          { all: all_records, unprotected: all_records.reject(&:protected?) }
        end
      end
    end

    private

    def validate_plan_limit_not_exceeded
      if Gitlab::Ci::Features.instance_level_variables_limit_enabled?
        super
      end
    end
  end
end
