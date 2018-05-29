# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ArchiveLegacyTraces
      class Build < ActiveRecord::Base
        include ::HasStatus

        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled # Disable STI

        belongs_to :project, foreign_key: :project_id, class_name: 'ArchiveLegacyTraces::Project'
        has_one :job_artifacts_trace, -> () { where(file_type: ArchiveLegacyTraces::JobArtifact.file_types[:trace]) }, class_name: 'ArchiveLegacyTraces::JobArtifact', foreign_key: :job_id
        has_many :trace_chunks, foreign_key: :build_id, class_name: 'ArchiveLegacyTraces::BuildTraceChunk'
    
        scope :finished, -> { where(status: [:success, :failed, :canceled]) }

        scope :without_new_traces, ->() do
          finished.where('NOT EXISTS (?)',
            BackgroundMigration::ArchiveLegacyTraces::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
        end

        def trace
          ::Gitlab::Ci::Trace.new(self)
        end

        def trace=(data)
          raise NotImplementedError
        end
    
        def old_trace
          read_attribute(:trace)
        end
    
        def erase_old_trace!
          update_column(:trace, nil)
        end
      end

      class JobArtifact < ActiveRecord::Base
        self.table_name = 'ci_job_artifacts'

        belongs_to :build
        belongs_to :project

        mount_uploader :file, JobArtifactUploader

        enum file_type: {
          archive: 1,
          metadata: 2,
          trace: 3
        }
      end

      class BuildTraceChunk < ActiveRecord::Base
        self.table_name = 'ci_build_trace_chunks'

        belongs_to :build
      end

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        has_many :builds, foreign_key: :project_id, class_name: 'ArchiveLegacyTraces::Build'
      end

      def perform(start_id, stop_id)
        BackgroundMigration::ArchiveLegacyTraces::Build
          .finished
          .without_new_traces
          .where(id: (start_id..stop_id)).find_each do |build|
            build.trace.archive!
          end
      end
    end
  end
end
