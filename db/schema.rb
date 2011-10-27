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

ActiveRecord::Schema.define(:version => 20111027142641) do

  create_table "issues", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "assignee_id"
    t.integer  "author_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "closed",      :default => false, :null => false
    t.integer  "position",    :default => 0
    t.boolean  "critical",    :default => false, :null => false
  end

  create_table "keys", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "key"
    t.string   "title"
    t.string   "identifier"
  end

  create_table "notes", :force => true do |t|
    t.text     "note",          :limit => 255
    t.string   "noteable_id"
    t.string   "noteable_type"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "attachment"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "path"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "private_flag", :default => true, :null => false
    t.string   "code"
    t.integer  "owner_id"
  end

  create_table "snippets", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "author_id",  :null => false
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_name"
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
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_projects", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "project_id",                    :null => false
    t.boolean  "read",       :default => false
    t.boolean  "write",      :default => false
    t.boolean  "admin",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
