# frozen_string_literal: true

class AddUsageDataIdToConversationalDevelopmentIndexMetrics < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :conversational_development_index_metrics, :usage_data_id, :bigint
  end
end
