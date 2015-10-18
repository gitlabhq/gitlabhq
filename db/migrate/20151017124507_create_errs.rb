class CreateErrs < ActiveRecord::Migration
  def change
    create_table :errs do |t|
      t.belongs_to :project, index: true
      t.string :error_class
      t.text :message
      t.string :request_url
      t.string :request_component
      t.string :request_action
      t.string :framework
      t.string :server_project_root
      t.text :server_environment
      t.boolean :resolved
      t.text :request
      t.text :notifier
      t.text :user_attributes

      t.timestamps
    end
  end
end
