# frozen_string_literal: true

class AddEnvironmentIdToClustersKubernetesNamespaces < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddReference
    add_reference :clusters_kubernetes_namespaces, :environment,
      index: true, type: :bigint, foreign_key: { on_delete: :nullify }
    # rubocop:enable Migration/AddReference
  end
end
