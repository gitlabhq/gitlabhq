# frozen_string_literal: true

module Postgresql
  class DetachedPartition < ::Gitlab::Database::SharedModel
    scope :ready_to_drop, -> { where('drop_after < ?', Time.current) }

    def fully_qualified_table_name
      "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{table_name}"
    end

    def table_schema
      Gitlab::Database::GitlabSchema.table_schema(table_name)
    end
  end
end
