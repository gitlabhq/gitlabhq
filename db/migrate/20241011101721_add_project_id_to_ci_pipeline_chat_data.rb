# frozen_string_literal: true

class AddProjectIdToCiPipelineChatData < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column(:ci_pipeline_chat_data, :project_id, :bigint)
  end
end
