class AddExternalAuthorizationServiceClassificationLabelToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects,
               :external_authorization_classification_label,
               :string
  end
end
