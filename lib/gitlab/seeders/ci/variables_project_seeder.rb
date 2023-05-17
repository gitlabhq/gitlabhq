# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      class VariablesProjectSeeder
        DEFAULT_SEED_COUNT = 10
        DEFAULT_PREFIX = 'VAR_'
        DEFAULT_ENV = '*'

        def initialize(params)
          @project = Project.find_by_full_path(params[:project_path])
          @seed_count = params[:seed_count] || DEFAULT_SEED_COUNT
          @environment_scope = params[:environment_scope] || DEFAULT_ENV
          @prefix = params[:prefix] || DEFAULT_PREFIX
        end

        def seed
          if @project.nil?
            warn 'ERROR: Project path is invalid.'
            return
          end

          max_id = project.variables.maximum(:id).to_i
          seed_count.times do
            max_id += 1
            create_ci_variable(max_id)
          end
        end

        private

        attr_reader :environment_scope, :prefix, :project, :seed_count

        def create_ci_variable(id)
          env = environment_scope == 'unique' ? "env_#{id}" : environment_scope
          key = "#{prefix}#{id}"

          if project.variables.by_environment_scope(env).find_by_key(key).present?
            warn "WARNING: Project CI Variable with key '#{key}' already exists. Skipping to next CI variable..."
          end

          project.variables.create(
            environment_scope: env,
            key: key,
            value: SecureRandom.hex(32)
          )
        end
      end
    end
  end
end
