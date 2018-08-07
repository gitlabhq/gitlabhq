# frozen_string_literal: true
class AddColumnsForHelmTillerCertificates < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters_applications_helm, :encrypted_ca_key, :text
    add_column :clusters_applications_helm, :encrypted_ca_key_iv, :text
    add_column :clusters_applications_helm, :ca_cert, :text
  end
end
