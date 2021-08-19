# frozen_string_literal: true

module Issuable
  class DestroyLabelLinksService
    BATCH_SIZE = 100

    def initialize(target_id, target_type)
      @target_id = target_id
      @target_type = target_type
    end

    def execute
      inner_query =
        LabelLink
          .select(:id)
          .for_target(target_id, target_type)
          .limit(BATCH_SIZE)

      delete_query = <<~SQL
      DELETE FROM "#{LabelLink.table_name}"
      WHERE id IN (#{inner_query.to_sql})
      SQL

      loop do
        result = LabelLink.connection.execute(delete_query)

        break if result.cmd_tuples == 0
      end
    end

    private

    attr_reader :target_id, :target_type
  end
end
