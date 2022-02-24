# frozen_string_literal: true

# This module adds PG full-text search capabilities to a model.
# A `search_data` association with a `search_vector` column is required.
#
# Declare the fields that will be part of the search vector with their
# corresponding weights. Possible values for weight are A, B, C, or D.
# For example:
#
# include PgFullTextSearchable
# pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }, { name: 'description', weight: 'B' }]
#
# This module sets up an after_commit hook that updates the search data
# when the searchable columns are changed. You will need to implement the
# `#persist_pg_full_text_search_vector` method that does the actual insert or update.
#
# This also adds a `pg_full_text_search` scope so you can do:
#
# Model.pg_full_text_search("some search term")

module PgFullTextSearchable
  extend ActiveSupport::Concern

  LONG_WORDS_REGEX = %r([A-Za-z0-9+/]{50,}).freeze
  TSVECTOR_MAX_LENGTH = 1.megabyte.freeze
  TEXT_SEARCH_DICTIONARY = 'english'

  def update_search_data!
    tsvector_sql_nodes = self.class.pg_full_text_searchable_columns.map do |column, weight|
      tsvector_arel_node(column, weight)&.to_sql
    end

    persist_pg_full_text_search_vector(Arel.sql(tsvector_sql_nodes.compact.join(' || ')))
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.cause.is_a?(PG::ProgramLimitExceeded) && e.message.include?('string is too long for tsvector')

    Gitlab::AppJsonLogger.error(
      message: 'Error updating search data: string is too long for tsvector',
      class: self.class.name,
      model_id: self.id
    )
  end

  private

  def persist_pg_full_text_search_vector(search_vector)
    raise NotImplementedError
  end

  def tsvector_arel_node(column, weight)
    return if self[column].blank?

    column_text = self[column].gsub(LONG_WORDS_REGEX, ' ')
    column_text = column_text[0..(TSVECTOR_MAX_LENGTH - 1)]
    column_text = ActiveSupport::Inflector.transliterate(column_text)

    Arel::Nodes::NamedFunction.new(
      'setweight',
      [
        Arel::Nodes::NamedFunction.new(
          'to_tsvector',
          [Arel::Nodes.build_quoted(TEXT_SEARCH_DICTIONARY), Arel::Nodes.build_quoted(column_text)]
        ),
        Arel::Nodes.build_quoted(weight)
      ]
    )
  end

  included do
    cattr_reader :pg_full_text_searchable_columns do
      {}
    end
  end

  class_methods do
    def pg_full_text_searchable(columns:)
      raise 'Full text search columns already defined!' if pg_full_text_searchable_columns.present?

      columns.each do |column|
        pg_full_text_searchable_columns[column[:name]] = column[:weight]
      end

      # We update this outside the transaction because this could raise an error if the resulting tsvector
      # is too long. When that happens, we still persist the create / update but the model will not have a
      # search data record. This is fine in most cases because this is a very rare occurrence and only happens
      # with strings that are most likely unsearchable anyway.
      #
      # We also do not want to use a subtransaction here due to: https://gitlab.com/groups/gitlab-org/-/epics/6540
      after_save_commit do
        next unless pg_full_text_searchable_columns.keys.any? { |f| saved_changes.has_key?(f) }

        update_search_data!
      end
    end

    def pg_full_text_search(search_term)
      search_data_table = reflect_on_association(:search_data).klass.arel_table

      joins(:search_data).where(
        Arel::Nodes::InfixOperation.new(
          '@@',
          search_data_table[:search_vector],
          Arel::Nodes::NamedFunction.new(
            'websearch_to_tsquery',
            [Arel::Nodes.build_quoted(TEXT_SEARCH_DICTIONARY), Arel::Nodes.build_quoted(search_term)]
          )
        )
      )
    end
  end
end
