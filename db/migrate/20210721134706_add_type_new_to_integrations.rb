# frozen_string_literal: true

class AddTypeNewToIntegrations < ActiveRecord::Migration[6.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210721134707_add_text_limit_to_integrations_type_new
  def change
    add_column :integrations, :type_new, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
