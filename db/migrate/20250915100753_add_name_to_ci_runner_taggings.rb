# frozen_string_literal: true

class AddNameToCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    # no-op due to incident https://app.incident.io/gitlab/incidents/4023
  end

  def down; end
end
