# frozen_string_literal: true

module Integrations
  class InstanceIntegration < Integration
    include IgnorableColumns

    self.table_name = 'instance_integrations'
    self.inheritance_column = :type_new # rubocop:disable Database/AvoidInheritanceColumn -- supporting instance integrations migration

    ignore_column :type, remove_with: '17.7', remove_after: '2024-12-02'
  end
end
