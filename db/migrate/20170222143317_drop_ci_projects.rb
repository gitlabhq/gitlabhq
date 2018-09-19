class DropCiProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    drop_table :ci_projects
  end

  def down
    create_table "ci_projects", force: :cascade do |t|
      t.string "name"
      t.integer "timeout", default: 3600, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "token"
      t.string "default_ref"
      t.string "path"
      t.boolean "always_build", default: false, null: false
      t.integer "polling_interval"
      t.boolean "public", default: false, null: false
      t.string "ssh_url_to_repo"
      t.integer "gitlab_id"
      t.boolean "allow_git_fetch", default: true, null: false
      t.string "email_recipients", default: "", null: false
      t.boolean "email_add_pusher", default: true, null: false
      t.boolean "email_only_broken_builds", default: true, null: false
      t.string "skip_refs"
      t.string "coverage_regex"
      t.boolean "shared_runners_enabled", default: false
      t.text "generated_yaml_config"
    end
  end
end
