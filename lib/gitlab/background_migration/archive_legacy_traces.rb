# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ArchiveLegacyTraces
      def perform(start_id, stop_id)
        # no-op
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/50712
      end
    end
  end
end
