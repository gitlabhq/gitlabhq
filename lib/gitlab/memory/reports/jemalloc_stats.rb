# frozen_string_literal: true

module Gitlab
  module Memory
    module Reports
      class JemallocStats
        # On prod, Jemalloc reports sizes were ~2.5 MB:
        # https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/15993#note_1014767214
        # We configured 1GB emptyDir per pod:
        # https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/1949
        # The pod will be evicted when the size limit is exceeded. We never want this to happen, for availability.
        #
        # With the default, we have a headroom (250*2.5MB=625<1000 MB) to fit into configured emptyDir.
        # It would allow us to keep 3+ days worth of reports for 6 workers running every 2 hours: 3*6*12=216<250
        #
        # The cleanup logic will be redundant after we'll implement the uploads, which would perform the cleanup.
        DEFAULT_MAX_REPORTS_STORED = 250

        def initialize(reports_path:, filename_label:)
          @reports_path = reports_path
          @filename_label = filename_label

          # Store report in tmp subdir while it is still streaming.
          # This will clearly separate finished reports from the files we are still writing to.
          @tmp_dir = File.join(@reports_path, 'tmp')
          FileUtils.mkdir_p(@tmp_dir)
        end

        def run
          return unless active?

          Gitlab::Memory::Jemalloc.dump_stats(path: reports_path, tmp_dir: @tmp_dir,
                                              filename_label: filename_label).tap do
            cleanup
          end
        end

        def active?
          Feature.enabled?(:report_jemalloc_stats, type: :ops)
        end

        private

        attr_reader :reports_path, :filename_label

        def cleanup
          reports_files_modified_order[0...-max_reports_stored].each do |f|
            File.unlink(f) if File.exist?(f)
          rescue Errno::ENOENT
            # Path does not exist: Ignore. We already check `File.exist?`
            # Rescue to be extra safe, because each worker could perform a cleanup
          end
        end

        def reports_files_modified_order
          pattern = File.join(reports_path, "#{Gitlab::Memory::Jemalloc::FILENAME_PREFIX}*")

          Dir.glob(pattern).sort_by do |f|
            test('M', f)
          rescue Errno::ENOENT
            # Path does not exist: Return any timestamp to proceed with the sort
            Time.current
          end
        end

        def max_reports_stored
          ENV["GITLAB_DIAGNOSTIC_REPORTS_JEMALLOC_MAX_REPORTS_STORED"] || DEFAULT_MAX_REPORTS_STORED
        end
      end
    end
  end
end
