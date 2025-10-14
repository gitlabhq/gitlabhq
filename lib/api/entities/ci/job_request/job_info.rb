# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class JobInfo < Grape::Entity
          expose :id, :name, :stage

          expose :project_id
          expose :project_name do |build|
            build.project.name
          end
          expose :project_full_path do |build|
            build.project.full_path
          end

          expose :namespace_id do |build|
            build.project.namespace_id
          end

          expose :root_namespace_id do |build|
            build.project.root_namespace.id
          end

          expose :organization_id do |build|
            build.project.organization_id
          end

          expose :instance_id, :instance_uuid
          expose :user_id, :scoped_user_id

          expose :time_in_queue_seconds
          expose :project_jobs_running_on_instance_runners_count
          expose :queue_size, :queue_depth
        end
      end
    end
  end
end
