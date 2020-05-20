# frozen_string_literal: true

class AddExternalHostnameToIngressAndKnative < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :clusters_applications_ingress, :external_hostname, :string
    add_column :clusters_applications_knative, :external_hostname, :string
  end
  # rubocop:enable Migration/PreventStrings
end
