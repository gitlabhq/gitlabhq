# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresIndex < ActiveRecord::Base
      include Gitlab::Utils::StrongMemoize

      self.table_name = 'postgres_indexes'
      self.primary_key = 'identifier'
      self.inheritance_column = :_type_disabled

      has_one :bloat_estimate, class_name: 'Gitlab::Database::PostgresIndexBloatEstimate', foreign_key: :identifier
      has_many :reindexing_actions, class_name: 'Gitlab::Database::Reindexing::ReindexAction', foreign_key: :index_identifier

      scope :by_identifier, ->(identifier) do
        raise ArgumentError, "Index name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        find(identifier)
      end

      # Indexes with reindexing support
      scope :reindexing_support, -> do
        where(partitioned: false, exclusion: false, expression: false, type: Gitlab::Database::Reindexing::SUPPORTED_TYPES)
          .not_match("#{Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$")
      end

      scope :reindexing_leftovers, -> { match("#{Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$") }

      scope :not_match, ->(regex) { where("name !~ ?", regex) }

      scope :match, ->(regex) { where("name ~* ?", regex) }

      scope :not_recently_reindexed, -> do
        recent_actions = Reindexing::ReindexAction.recent.where('index_identifier = identifier')

        where('NOT EXISTS (?)', recent_actions)
      end

      def reset
        reload # rubocop:disable Cop/ActiveRecordAssociationReload
        clear_memoization(:bloat_size)
      end

      def bloat_size
        strong_memoize(:bloat_size) { bloat_estimate&.bloat_size || 0 }
      end

      def relative_bloat_level
        bloat_size / ondisk_size_bytes.to_f
      end

      def to_s
        name
      end
    end
  end
end
