# frozen_string_literal: true

module Gitlab
  module Seeders
    class ProjectEnvironmentSeeder
      DEFAULT_SEED_COUNT = 10
      DEFAULT_PREFIX = 'ENV_'

      def initialize(params)
        @project = Project.find_by_full_path(params[:project_path])
        @seed_count = params[:seed_count] || DEFAULT_SEED_COUNT
        @prefix = params[:prefix] || DEFAULT_PREFIX
      end

      def seed
        if @project.nil?
          warn 'ERROR: Project path is invalid.'
          return
        end

        max_id = project.environments.maximum(:id).to_i
        seed_count.times do
          max_id += 1
          create_project_environment_scope(max_id)
        end
      end

      private

      attr_reader :project, :seed_count, :prefix

      def create_project_environment_scope(id)
        name = "#{prefix}#{id}"

        if project.environments.find_by_name(name).present?
          warn "WARNING: Project Environment '#{name}' already exists. Skipping to next CI variable..."
          return
        end

        project.environments.create(name: name)
      end
    end
  end
end
