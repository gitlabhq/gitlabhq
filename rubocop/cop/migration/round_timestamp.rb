# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Flags migration files whose version ends in `0000`. Such a version was
      # typed by hand (a date plus an hour) instead of generated, and two merge
      # requests that pick the same hand-made version collide on the marker file
      # in `schema_migrations`. Existing files are accepted through `EnforcedSince`.
      #
      # @example
      #   # bad
      #   db/migrate/20261001090000_add_index_to_users.rb
      #
      #   # good
      #   db/migrate/20261001093412_add_index_to_users.rb
      class RoundTimestamp < RuboCop::Cop::Base
        include MigrationHelpers
        include RangeHelp

        MSG = 'Migration version %{version} ends in 0000, which suggests it was written by hand. %{advice}'
        SCRIPT_ADVICE = 'Run `scripts/refresh-migrations-timestamps` to give new migrations a generated, ' \
          'unique version.'
        MANUAL_ADVICE = 'Rename the file and its `schema_migrations` marker to the current UTC time ' \
          '(`date -u +%Y%m%d%H%M%S`) so the version is unique.'

        VERSION_PATTERN = /\A(?<version>\d{14})_/

        # Directories handled by scripts/refresh-migrations-timestamps (its MIGRATION_DIRS).
        SCRIPT_DIRS = %r{(\A|/)db/(post_)?migrate/[^/]+\z}

        def on_new_investigation
          version = file_version
          return unless version
          return unless version.end_with?('0000')
          return if enforced_since && version.to_i <= enforced_since

          add_offense(
            source_range(processed_source.buffer, 1, 0),
            message: format(MSG, version: version, advice: advice)
          )
        end

        private

        def file_version
          File.basename(processed_source.file_path)[VERSION_PATTERN, :version]
        end

        def advice
          processed_source.file_path.match?(SCRIPT_DIRS) ? SCRIPT_ADVICE : MANUAL_ADVICE
        end
      end
    end
  end
end
