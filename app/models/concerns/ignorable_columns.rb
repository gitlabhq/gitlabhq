# frozen_string_literal: true

module IgnorableColumns
  extend ActiveSupport::Concern

  ColumnIgnore = Struct.new(:remove_after, :remove_with, :remove_never) do
    def safe_to_remove?
      return false if remove_never

      Date.today > remove_after
    end
  end

  class_methods do
    # Ignore database columns in a model
    #
    # Indicate the earliest date and release we can stop ignoring the column with +remove_after+ (a date string) and +remove_with+ (a release)
    def ignore_columns(*columns, remove_after: nil, remove_with: nil, remove_never: false)
      unless remove_never
        raise ArgumentError, 'Please indicate when we can stop ignoring columns with remove_after (date string YYYY-MM-DD), example: ignore_columns(:name, remove_after: \'2019-12-01\', remove_with: \'12.6\')' unless remove_after && Gitlab::Regex.utc_date_regex.match?(remove_after)
        raise ArgumentError, 'Please indicate in which release we can stop ignoring columns with remove_with, example: ignore_columns(:name, remove_after: \'2019-12-01\', remove_with: \'12.6\')' unless remove_with
      end

      self.ignored_columns += columns.flatten # rubocop:disable Cop/IgnoredColumns

      columns.flatten.each do |column|
        remove_after_date = remove_after ? Date.parse(remove_after) : nil
        self.ignored_columns_details[column.to_sym] = ColumnIgnore.new(remove_after_date, remove_with, remove_never)
      end
    end

    alias_method :ignore_column, :ignore_columns

    def ignored_columns_details
      return @ignored_columns_details if defined?(@ignored_columns_details)

      IGNORE_COLUMN_MONITOR.synchronize do
        @ignored_columns_details ||= superclass.try(:ignored_columns_details)&.dup || {}
      end
    end

    IGNORE_COLUMN_MONITOR = Monitor.new
  end
end
