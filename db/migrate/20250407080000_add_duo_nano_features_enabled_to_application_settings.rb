# frozen_string_literal: true

class AddDuoNanoFeaturesEnabledToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    # rubocop: disable Migration/SaferBooleanColumn -- More control over this setting is needed to know if the user
    # took action, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186948#note_2437007321.
    add_column :application_settings, :duo_nano_features_enabled, :boolean, null: true
    # rubocop: enable Migration/SaferBooleanColumn
  end
end
