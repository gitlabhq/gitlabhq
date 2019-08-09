# frozen_string_literal: true

class DeleteKubernetesServices < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    Service.where(type: "KubernetesService").delete_all
  end

  def down
    # no-op
  end
end
