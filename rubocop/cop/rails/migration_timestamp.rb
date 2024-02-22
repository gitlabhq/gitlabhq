# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Rails
      # Checks to ensure timestamp used for a migration file occurs in the past.
      # If it is not in the past, this can cause Rails to enumerate the file names until that date has passed.
      # For instance if the migration below exists:
      #   30000220000000_some_migration.rb
      # It will cause rails generator to create new migrations as an enumeration on that timestamp until 30000220 has
      # passed. We would be generating files like this:
      #   30000220000001_some_migration.rb
      #   30000220000002_some_migration.rb
      # That methodology increases the probability of collision with others contributing at the same time
      # as each file is merely enumerated by 1.
      #
      # @example
      #   # bad - date is in the future
      #   30000220000000_some_migration.rb
      #
      #   # good - date is in the past
      #   20240219000000_some_migration.rb
      #
      class MigrationTimestamp < RuboCop::Cop::Base
        include RangeHelp

        MSG = 'The date of this file (`%<basename>s`) must not be in the future.'

        def on_new_investigation
          file_path = processed_source.file_path
          basename = File.basename(file_path)

          return unless date_named_file?(basename)

          for_bad_filename(basename) { |range, msg| add_offense(range, message: msg) }
        end

        private

        DATE_LENGTH = 14
        STARTS_WITH_DATE_REGEX = /^\d{#{DATE_LENGTH}}_/

        def date_named_file?(basename)
          basename.match?(STARTS_WITH_DATE_REGEX)
        end

        def for_bad_filename(basename)
          # match ActiveRecord https://api.rubyonrails.org/classes/ActiveRecord/Migration.html
          now = Time.now.utc.strftime('%Y%m%d%H%M%S') # length is 14

          return if basename.first(DATE_LENGTH) <= now

          yield source_range(processed_source.buffer, 1, 0), format(MSG, basename: basename)
        end
      end
    end
  end
end
