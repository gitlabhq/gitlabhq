# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      class VariablesInstanceSeeder
        DEFAULT_SEED_COUNT = 10
        DEFAULT_PREFIX = 'INSTANCE_VAR_'

        def initialize(params = {})
          @seed_count = params[:seed_count] || DEFAULT_SEED_COUNT
          @prefix = params[:prefix] || DEFAULT_PREFIX
        end

        def seed
          max_id = ::Ci::InstanceVariable.maximum(:id).to_i
          seed_count.times do
            max_id += 1
            create_ci_variable(max_id)
          end
        end

        private

        attr_reader :prefix, :seed_count

        def create_ci_variable(id)
          key = "#{prefix}#{id}"

          if ::Ci::InstanceVariable.find_by_key(key)
            warn "WARNING: Instance CI Variable with key '#{key}' already exists. Skipping to next CI variable..."
            return
          end

          ::Ci::InstanceVariable.new(
            key: key,
            value: SecureRandom.hex(32)
          ).save
        end
      end
    end
  end
end
