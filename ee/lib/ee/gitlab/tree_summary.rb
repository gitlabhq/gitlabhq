module EE
  module Gitlab
    module TreeSummary
      extend ::Gitlab::Utils::Override

      include ::PathLocksHelper

      override :summarize
      def summarize
        summary, commits = super
        summary.tap { |summary| fill_path_locks!(summary) }

        [summary, commits]
      end

      private

      # FIXME: Loading the path locks from the database is an N+1 problem
      # https://gitlab.com/gitlab-org/gitlab-ee/issues/7481
      def fill_path_locks!(entries)
        entries.each do |entry|
          path = entry_path(entry)
          path_lock = project.find_path_lock(path)

          entry[:lock_label] = path_lock && text_label_for_lock(path_lock, path)
        end
      end
    end
  end
end
