diff --git a/db/migrate/20161010142410_create_project_authorizations.rb b/db/migrate/20161010142410_create_project_authorizations.rb
new file mode 100644
index 0000000..e095ab9
--- /dev/null
+++ b/db/migrate/20161010142410_create_project_authorizations.rb
@@ -0,0 +1,15 @@
+class CreateProjectAuthorizations < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = false
+
+  def change
+    create_table :project_authorizations do |t|
+      t.references :user, foreign_key: { on_delete: :cascade }
+      t.references :project, foreign_key: { on_delete: :cascade }
+      t.integer :access_level
+
+      t.index [:user_id, :project_id, :access_level], unique: true, name: 'index_project_authorizations_on_user_id_project_id_access_level'
+    end
+  end
+end
diff --git a/db/migrate/20161017091941_add_authorized_projects_populated_to_users.rb b/db/migrate/20161017091941_add_authorized_projects_populated_to_users.rb
new file mode 100644
index 0000000..8f6be9d
--- /dev/null
+++ b/db/migrate/20161017091941_add_authorized_projects_populated_to_users.rb
@@ -0,0 +1,9 @@
+class AddAuthorizedProjectsPopulatedToUsers < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = false
+
+  def change
+    add_column :users, :authorized_projects_populated, :boolean
+  end
+end
diff --git a/db/migrate/20161020083353_add_pipeline_id_to_merge_request_metrics.rb b/db/migrate/20161020083353_add_pipeline_id_to_merge_request_metrics.rb
new file mode 100644
index 0000000..f49df68
--- /dev/null
+++ b/db/migrate/20161020083353_add_pipeline_id_to_merge_request_metrics.rb
@@ -0,0 +1,33 @@
+# See http://doc.gitlab.com/ce/development/migration_style_guide.html
+# for more information on how to write migrations for GitLab.
+
+class AddPipelineIdToMergeRequestMetrics < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  disable_ddl_transaction!
+
+  # Set this constant to true if this migration requires downtime.
+  DOWNTIME = true
+
+  # When a migration requires downtime you **must** uncomment the following
+  # constant and define a short and easy to understand explanation as to why the
+  # migration requires downtime.
+  DOWNTIME_REASON = 'Adding a foreign key'
+
+  # When using the methods "add_concurrent_index" or "add_column_with_default"
+  # you must disable the use of transactions as these methods can not run in an
+  # existing transaction. When using "add_concurrent_index" make sure that this
+  # method is the _only_ method called in the migration, any other changes
+  # should go in a separate migration. This ensures that upon failure _only_ the
+  # index creation fails and can be retried or reverted easily.
+  #
+  # To disable transactions uncomment the following line and remove these
+  # comments:
+  # disable_ddl_transaction!
+
+  def change
+    add_column :merge_request_metrics, :pipeline_id, :integer
+    add_concurrent_index :merge_request_metrics, :pipeline_id
+    add_foreign_key :merge_request_metrics, :ci_commits, column: :pipeline_id, on_delete: :cascade
+  end
+end
diff --git a/db/migrate/20161030005533_add_estimate_to_issuables.rb b/db/migrate/20161030005533_add_estimate_to_issuables.rb
new file mode 100644
index 0000000..96e7593
--- /dev/null
+++ b/db/migrate/20161030005533_add_estimate_to_issuables.rb
@@ -0,0 +1,35 @@
+# See http://doc.gitlab.com/ce/development/migration_style_guide.html
+# for more information on how to write migrations for GitLab.
+
+class AddEstimateToIssuables < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  # Set this constant to true if this migration requires downtime.
+  DOWNTIME = false
+
+  # When a migration requires downtime you **must** uncomment the following
+  # constant and define a short and easy to understand explanation as to why the
+  # migration requires downtime.
+  # DOWNTIME_REASON = ''
+
+  # When using the methods "add_concurrent_index" or "add_column_with_default"
+  # you must disable the use of transactions as these methods can not run in an
+  # existing transaction. When using "add_concurrent_index" make sure that this
+  # method is the _only_ method called in the migration, any other changes
+  # should go in a separate migration. This ensures that upon failure _only_ the
+  # index creation fails and can be retried or reverted easily.
+  #
+  # To disable transactions uncomment the following line and remove these
+  # comments:
+  # disable_ddl_transaction!
+
+  def up
+    add_column :issues, :time_estimate, :integer
+    add_column :merge_requests, :time_estimate, :integer
+  end
+
+  def down
+    remove_column :issues, :time_estimate
+    remove_column :merge_requests, :time_estimate
+  end
+end
diff --git a/db/migrate/20161030020610_create_timelogs.rb b/db/migrate/20161030020610_create_timelogs.rb
new file mode 100644
index 0000000..31183ae
--- /dev/null
+++ b/db/migrate/20161030020610_create_timelogs.rb
@@ -0,0 +1,18 @@
+class CreateTimelogs < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = false
+
+  def change
+    create_table :timelogs do |t|
+      t.integer :time_spent, null: false
+      t.references :trackable, polymorphic: true
+      t.references :user
+
+      t.timestamps null: false
+    end
+
+    add_index :timelogs, [:trackable_type, :trackable_id]
+    add_index :timelogs, :user_id
+  end
+end
diff --git a/db/migrate/20161031171301_add_project_id_to_subscriptions.rb b/db/migrate/20161031171301_add_project_id_to_subscriptions.rb
new file mode 100644
index 0000000..9753467
--- /dev/null
+++ b/db/migrate/20161031171301_add_project_id_to_subscriptions.rb
@@ -0,0 +1,14 @@
+class AddProjectIdToSubscriptions < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = false
+
+  def up
+    add_column :subscriptions, :project_id, :integer
+    add_foreign_key :subscriptions, :projects, column: :project_id, on_delete: :cascade
+  end
+
+  def down
+    remove_column :subscriptions, :project_id
+  end
+end
diff --git a/db/migrate/20161031174110_migrate_subscriptions_project_id.rb b/db/migrate/20161031174110_migrate_subscriptions_project_id.rb
new file mode 100644
index 0000000..549145a
--- /dev/null
+++ b/db/migrate/20161031174110_migrate_subscriptions_project_id.rb
@@ -0,0 +1,44 @@
+class MigrateSubscriptionsProjectId < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = true
+  DOWNTIME_REASON = 'Subscriptions will not work as expected until this migration is complete.'
+
+  def up
+    execute <<-EOF.strip_heredoc
+      UPDATE subscriptions
+      SET project_id = (
+        SELECT issues.project_id
+        FROM issues
+        WHERE issues.id = subscriptions.subscribable_id
+      )
+      WHERE subscriptions.subscribable_type = 'Issue';
+    EOF
+
+    execute <<-EOF.strip_heredoc
+      UPDATE subscriptions
+      SET project_id = (
+        SELECT merge_requests.target_project_id
+        FROM merge_requests
+        WHERE merge_requests.id = subscriptions.subscribable_id
+      )
+      WHERE subscriptions.subscribable_type = 'MergeRequest';
+    EOF
+
+    execute <<-EOF.strip_heredoc
+      UPDATE subscriptions
+      SET project_id = (
+        SELECT projects.id
+        FROM labels INNER JOIN projects ON projects.id = labels.project_id
+        WHERE labels.id = subscriptions.subscribable_id
+      )
+      WHERE subscriptions.subscribable_type = 'Label';
+    EOF
+  end
+
+  def down
+    execute <<-EOF.strip_heredoc
+      UPDATE subscriptions SET project_id = NULL;
+    EOF
+  end
+end
diff --git a/db/migrate/20161031181638_add_unique_index_to_subscriptions.rb b/db/migrate/20161031181638_add_unique_index_to_subscriptions.rb
new file mode 100644
index 0000000..4b1b29e
--- /dev/null
+++ b/db/migrate/20161031181638_add_unique_index_to_subscriptions.rb
@@ -0,0 +1,18 @@
+class AddUniqueIndexToSubscriptions < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = true
+  DOWNTIME_REASON = 'This migration requires downtime because it changes a column to not accept null values.'
+
+  disable_ddl_transaction!
+
+  def up
+    add_concurrent_index :subscriptions, [:subscribable_id, :subscribable_type, :user_id, :project_id], { unique: true, name: 'index_subscriptions_on_subscribable_and_user_id_and_project_id' }
+    remove_index :subscriptions, name: 'subscriptions_user_id_and_ref_fields' if index_name_exists?(:subscriptions, 'subscriptions_user_id_and_ref_fields', false)
+  end
+
+  def down
+    add_concurrent_index :subscriptions, [:subscribable_id, :subscribable_type, :user_id], { unique: true, name: 'subscriptions_user_id_and_ref_fields' }
+    remove_index :subscriptions, name: 'index_subscriptions_on_subscribable_and_user_id_and_project_id' if index_name_exists?(:subscriptions, 'index_subscriptions_on_subscribable_and_user_id_and_project_id', false)
+  end
+end
diff --git a/db/migrate/20161113184239_create_user_chat_names_table.rb b/db/migrate/20161113184239_create_user_chat_names_table.rb
new file mode 100644
index 0000000..97b5976
--- /dev/null
+++ b/db/migrate/20161113184239_create_user_chat_names_table.rb
@@ -0,0 +1,21 @@
+class CreateUserChatNamesTable < ActiveRecord::Migration
+  include Gitlab::Database::MigrationHelpers
+
+  DOWNTIME = false
+
+  def change
+    create_table :chat_names do |t|
+      t.integer :user_id, null: false
+      t.integer :service_id, null: false
+      t.string :team_id, null: false
+      t.string :team_domain
+      t.string :chat_id, null: false
+      t.string :chat_name
+      t.datetime :last_used_at
+      t.timestamps null: false
+    end
+
+    add_index :chat_names, [:user_id, :service_id], unique: true
+    add_index :chat_names, [:service_id, :team_id, :chat_id], unique: true
+  end
+end
diff --git a/db/migrate/20161117114805_remove_undeleted_groups.rb b/db/migrate/20161117114805_remove_undeleted_groups.rb
new file mode 100644
index 0000000..ebc2d97
--- /dev/null
+++ b/db/migrate/20161117114805_remove_undeleted_groups.rb
@@ -0,0 +1,16 @@
+# See http://doc.gitlab.com/ce/development/migration_style_guide.html
+# for more information on how to write migrations for GitLab.
+
+class RemoveUndeletedGroups < ActiveRecord::Migration
+  DOWNTIME = false
+
+  def up
+    execute "DELETE FROM namespaces WHERE deleted_at IS NOT NULL;"
+  end
+
+  def down
+    # This is an irreversible migration;
+    # If someone is trying to rollback for other reasons, we should not throw an Exception.
+    # raise ActiveRecord::IrreversibleMigration
+  end
+end
