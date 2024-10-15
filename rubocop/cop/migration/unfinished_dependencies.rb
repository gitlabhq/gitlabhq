# frozen_string_literal: true

require_relative '../../migration_helpers'
require_relative '../../../lib/gitlab/utils/batched_background_migrations_dictionary'

module RuboCop
  module Cop
    module Migration
      # Checks if there are any unfinished dependent batched bg migrations
      class UnfinishedDependencies < RuboCop::Cop::Base
        include MigrationHelpers

        NOT_FINALIZED_MSG = <<-MESSAGE.delete("\n").squeeze(' ').strip
          Dependent migration with queued version %{version} is not yet finalized.
          Consider finalizing the dependent migration and update it's finalized_by attr in the dictionary.
        MESSAGE

        FINALIZED_BY_LATER_MIGRATION_MSG = <<-MESSAGE.delete("\n").squeeze(' ').strip
          Dependent migration with queued version %{version} is finalized by later migration,
          it has to be finalized before the current migration.
        MESSAGE

        def_node_matcher :dependent_migration_versions, <<~PATTERN
          (casgn nil? :DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS (array $...))
        PATTERN

        def on_casgn(node)
          return unless in_migration?(node)

          migration_version = version(node)

          dependent_migration_versions(node)&.each do |dependent_migration_version_node|
            dependent_migration_version = dependent_migration_version_node.value
            finalized_by_version = fetch_finalized_by(dependent_migration_version)

            next if finalized_by_version.present? && finalized_by_version.to_s < migration_version.to_s

            msg = finalized_by_version.present? ? FINALIZED_BY_LATER_MIGRATION_MSG : NOT_FINALIZED_MSG
            add_offense(node, message: format(msg, version: dependent_migration_version))
          end
        end

        private

        def fetch_finalized_by(queued_migration_version)
          ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary
            .new(queued_migration_version)
            .finalized_by
        end
      end
    end
  end
end
