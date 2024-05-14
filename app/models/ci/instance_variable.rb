# frozen_string_literal: true

module Ci
  class InstanceVariable < Ci::ApplicationRecord
    extend Gitlab::ProcessMemoryCache::Helper
    include Ci::NewHasVariable
    include Ci::Maskable
    include Ci::RawVariable
    include Limitable

    self.limit_name = 'ci_instance_level_variables'
    self.limit_scope = Limitable::GLOBAL_SCOPE

    alias_attribute :secret_value, :value

    validates :description, length: { maximum: 255 }, allow_blank: true
    validates :key, uniqueness: {
      message: ->(object, data) { _("(%{value}) has already been taken") }
    }

    validates :value, length: {
      maximum: 10_000,
      too_long: ->(object, data) do
        _('The value of the provided variable exceeds the %{count} character limit')
      end
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

    def audit_details
      key
    end
  end
end
