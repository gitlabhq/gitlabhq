# frozen_string_literal: true

class AddEnvironmentIdToClustersKubernetesNamespaces < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_reference :clusters_kubernetes_namespaces, :environment,
      index: true, type: :bigint, foreign_key: { on_delete: :nullify }
  end
end
