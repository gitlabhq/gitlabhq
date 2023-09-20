# frozen_string_literal: true

module CrossDatabaseIgnoredTables
  extend ActiveSupport::Concern

  class_methods do
    def temporary_ignore_cross_database_tables(tables, url:, &blk)
      Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
        tables, url: url, &blk
      )
    end

    def cross_database_ignore_tables(tables, options = {})
      raise "missing issue url" if options[:url].blank?

      options[:on] = %I[save destroy] if options[:on].blank?
      events = Array.wrap(options[:on])
      tables = Array.wrap(tables)

      events.each do |event|
        register_ignored_cross_database_event(tables, event, options)
      end
    end

    private

    def register_ignored_cross_database_event(tables, event, options)
      case event
      when :save
        around_save(prepend: true) { |_, blk| temporary_ignore_cross_database_tables(tables, options, &blk) }
      when :create
        around_create(prepend: true) { |_, blk| temporary_ignore_cross_database_tables(tables, options, &blk) }
      when :update
        around_update(prepend: true) { |_, blk| temporary_ignore_cross_database_tables(tables, options, &blk) }
      when :destroy
        around_destroy(prepend: true) { |_, blk| temporary_ignore_cross_database_tables(tables, options, &blk) }
      else
        raise "Unknown #{event}"
      end
    end
  end

  private

  def temporary_ignore_cross_database_tables(tables, options, &blk)
    return yield unless options[:if].nil? || instance_eval(&options[:if])

    url = options[:url]

    self.class.temporary_ignore_cross_database_tables(tables, url: url, &blk)
  end
end
