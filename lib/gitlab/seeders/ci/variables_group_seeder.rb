# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      class VariablesGroupSeeder
        DEFAULT_SEED_COUNT = 10
        DEFAULT_PREFIX = 'GROUP_VAR_'
        DEFAULT_ENV = '*'

        def initialize(params)
          @group = Group.find_by_name(params[:name])
          @seed_count = params[:seed_count] || DEFAULT_SEED_COUNT
          @environment_scope = params[:environment_scope] || DEFAULT_ENV
          @prefix = params[:prefix] || DEFAULT_PREFIX
        end

        def seed
          if @group.nil?
            warn 'ERROR: Group name is invalid.'
            return
          end

          max_id = group.variables.maximum(:id).to_i
          seed_count.times do
            max_id += 1
            create_ci_variable(max_id)
          end
        end

        private

        attr_reader :environment_scope, :group, :prefix, :seed_count

        def create_ci_variable(id)
          env = environment_scope == 'unique' ? "env_#{id}" : environment_scope
          key = "#{prefix}#{id}"

          if group.variables.by_environment_scope(env).find_by_key(key).present?
            warn "WARNING: Group CI Variable with key '#{key}' already exists. Skipping to next CI variable..."
            return
          end

          group.variables.create(
            environment_scope: env,
            key: key,
            value: SecureRandom.hex(32)
          )
        end
      end
    end
  end
end
