# frozen_string_literal: true

class CreateWorkspacesTable < Gitlab::Database::Migration[2.1]
  def up
    create_table :workspaces do |t|
      t.timestamps_with_timezone null: false
      # NOTE: All workspace foreign key references are currently `on_delete: :cascade`, because we have no support or
      #       testing around null values. However, in the future we may want to switch these to nullify, especially
      #       once we start introducing logging, metrics, billing, etc. around workspaces.
      t.bigint :user_id, null: false, index: true
      t.bigint :project_id, null: false, index: true
      t.bigint :cluster_agent_id, null: false, index: true
      t.datetime_with_timezone :desired_state_updated_at, null: false
      t.datetime_with_timezone :responded_to_agent_at
      t.integer :max_hours_before_termination, limit: 2, null: false
      t.text :name, limit: 64, null: false, index: { unique: true }
      t.text :namespace, limit: 64, null: false
      t.text :desired_state, limit: 32, null: false
      t.text :actual_state, limit: 32, null: false
      t.text :editor, limit: 256, null: false
      t.text :devfile_ref, limit: 256, null: false
      t.text :devfile_path, limit: 2048, null: false
      # NOTE: The limit on the devfile fields are arbitrary, and only added to avoid a rubocop
      #       Migration/AddLimitToTextColumns error. We expect the average devfile side to be small, perhaps ~0.5k for a
      #       devfile and ~2k for a processed_devfile, but to account for unexpected usage resulting in larger files,
      #       we have specified 65535, which allows for a YAML file with over 800 lines of an average 80-character
      #       length.
      t.text :devfile, limit: 65535
      t.text :processed_devfile, limit: 65535
      t.text :url, limit: 1024, null: false
      # NOTE: The resource version is currently backed by etcd's mod_revision.
      #       However, it's important to note that the application should not rely on the implementation details of
      #       the versioning system maintained by Kubernetes. We may change the implementation of resource version
      #       in the future, such as to change it to a timestamp or per-object counter.
      #       https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency
      #       The limit of 64 is arbitrary.
      t.text :deployment_resource_version, limit: 64
    end
  end

  def down
    drop_table :workspaces
  end
end
