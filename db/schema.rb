# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120219193300) do

  create_table "issues", :force => true do |t|
    t.string   "title"
    t.integer  "assignee_id"
    t.integer  "author_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "closed",      :default => false, :null => false
    t.integer  "position",    :default => 0
    t.boolean  "critical",    :default => false, :null => false
    t.string   "branch_name"
  end

  add_index "issues", ["project_id"], :name => "index_issues_on_project_id"

  create_table "keys", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "key"
    t.string   "title"
    t.string   "identifier"
    t.integer  "project_id"
  end

  create_table "merge_requests", :force => true do |t|
    t.string   "target_branch",                    :null => false
    t.string   "source_branch",                    :null => false
    t.integer  "project_id",                       :null => false
    t.integer  "author_id"
    t.integer  "assignee_id"
    t.string   "title"
    t.boolean  "closed",        :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "merge_requests", ["project_id"], :name => "index_merge_requests_on_project_id"

  create_table "notes", :force => true do |t|
    t.text     "note"
    t.string   "noteable_id"
    t.string   "noteable_type"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "attachment"
    t.string   "line_code"
  end

  add_index "notes", ["noteable_id"], :name => "index_notes_on_noteable_id"
  add_index "notes", ["noteable_type"], :name => "index_notes_on_noteable_type"

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "path"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "private_flag",           :default => true,     :null => false
    t.string   "code"
    t.integer  "owner_id"
    t.string   "default_branch",         :default => "master", :null => false
    t.boolean  "issues_enabled",         :default => true,     :null => false
    t.boolean  "wall_enabled",           :default => true,     :null => false
    t.boolean  "merge_requests_enabled", :default => true,     :null => false
    t.boolean  "wiki_enabled",           :default => true,     :null => false
  end

  create_table "protected_branches", :force => true do |t|
    t.integer  "project_id", :null => false
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "snippets", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "author_id",  :null => false
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_name"
    t.datetime "expires_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",    :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "admin",                                 :default => false, :null => false
    t.integer  "projects_limit",                        :default => 10
    t.string   "skype",                                 :default => "",    :null => false
    t.string   "linkedin",                              :default => "",    :null => false
    t.string   "twitter",                               :default => "",    :null => false
    t.string   "authentication_token"
    t.boolean  "dark_scheme",                           :default => false, :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_projects", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "project_id",                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_access", :default => 0, :null => false
  end

  create_table "web_hooks", :force => true do |t|
    t.string   "url"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wikis", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "slug"
    t.integer  "user_id"
  end

end
