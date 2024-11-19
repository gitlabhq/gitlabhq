# frozen_string_literal: true

module Backup
  module Tasks
    class Database < Task
      def self.id = 'db'

      def human_name = _('database')

      def destination_path = 'db'

      def cleanup_path = 'db'

      def pre_restore_warning
        return if options.force

        <<-MSG.strip_heredoc
        Be sure to stop Puma, Sidekiq, and any other process that
        connects to the database before proceeding. For Omnibus
        installs, see the following link for more information:
        #{help_page_url('administration/backup_restore/restore_gitlab.md', 'restore-for-linux-package-installations')}

        Before restoring the database, we will remove all existing
        tables to avoid future upgrade problems. Be aware that if you have
        custom tables in the GitLab database these tables and all data will be
        removed.
        MSG
      end

      def post_restore_warning
        return if target.errors.empty?

        <<-MSG.strip_heredoc
        There were errors in restoring the schema. This may cause
        issues if this results in missing indexes, constraints, or
        columns. Please record the errors above and contact GitLab
        Support if you have questions:
        https://about.gitlab.com/support/
        MSG
      end

      private

      def target
        @target ||= ::Backup::Targets::Database.new(progress, options: options)
      end

      def help_page_url(path, anchor = nil)
        ::Gitlab::Routing.url_helpers.help_page_url(path, anchor: anchor)
      end
    end
  end
end
