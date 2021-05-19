# frozen_string_literal: true

class DeleteKubernetesServices < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  class Service < ActiveRecord::Base
    self.table_name = 'services'
    self.inheritance_column = :_type_disabled
  end

  def up
    Service.where(type: "KubernetesService").delete_all
  end

  def down
    # no-op
  end
end
