# frozen_string_literal: true
class AddColumnsForHelmTillerCertificates < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :clusters_applications_helm, :encrypted_ca_key, :text
    add_column :clusters_applications_helm, :encrypted_ca_key_iv, :text
    add_column :clusters_applications_helm, :ca_cert, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
