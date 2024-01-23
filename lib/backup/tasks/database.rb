# frozen_string_literal: true

module Backup
  module Tasks
    class Database < Task
      def self.id = 'db'

      def human_name = _('database')

      def destination_path = 'db'

      def cleanup_path = 'db'

      def target
        ::Backup::Targets::Database.new(progress, options: options, force: options.force?)
      end
    end
  end
end
