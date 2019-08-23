# frozen_string_literal: true

class AddExternalHostnameToIngressAndKnative < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :clusters_applications_ingress, :external_hostname, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :clusters_applications_knative, :external_hostname, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
