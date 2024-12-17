# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        class BuildsTagsConfiguration
          def self.applies_to?(record)
            record.is_a?(::Ci::Build)
          end

          def self.build_from(job)
            new(job.project)
          end

          def initialize(project)
            @project = project
          end

          def join_model
            ::Ci::BuildTag
          end

          def unique_by
            [:tag_id, :build_id, :partition_id]
          end

          def attributes_map(job)
            {
              build_id: job.id,
              partition_id: job.partition_id,
              project_id: job.project_id
            }
          end

          def polymorphic_taggings?
            true
          end

          def monomorphic_taggings?(_taggable)
            true
          end
        end
      end
    end
  end
end
