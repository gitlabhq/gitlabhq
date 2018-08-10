# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPlanIdToNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'
  end

  class Plan < ActiveRecord::Base
    self.table_name = 'plans'
  end

  def up
    add_reference :namespaces, :plan # rubocop:disable Migration/AddReference
    add_concurrent_foreign_key :namespaces, :plans, column: :plan_id, on_delete: :nullify
    add_concurrent_index :namespaces, :plan_id

    Plan.all.each do |plan|
      Namespace.where(plan: plan.name).update_all(plan_id: plan.id)
    end
  end

  def down
    remove_foreign_key :namespaces, column: :plan_id
    remove_concurrent_index :namespaces, :plan_id
    remove_reference :namespaces, :plan
  end
end
