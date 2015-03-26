class ChangeMysqlCollateToUtf8mb4 < ActiveRecord::Migration
  def up
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/
    [:users, :subscriptions, :schema_migrations, :oauth_applications, :oauth_access_tokens, :oauth_access_grants, :namespaces, :keys, :emails].each do |table|
      ActiveRecord::Base.connection.indexes(table).each do |index|
        remove_index table, :name => index.name if index.name != :id
      end
      execute "ALTER TABLE `#{table}` CONVERT TO character set utf8mb4 COLLATE utf8mb4_unicode_ci;"
    end

    [:email, :authentication_token, :reset_password_token, :confirmation_token].each do |col|
      add_index :users, col, unique: true, length: 190
    end
    [:name, :username].each do |col|
      add_index :users, col, length: 190
    end
    add_index :users, [:created_at, :id]
    add_index :users, :admin
    add_index :users, :current_sign_in_at

    add_index :subscriptions, [:subscribable_id, :subscribable_type, :user_id], length: {:subscribable_type => 170}, name: :subscriptions_user_id_and_ref_fields

    add_index :schema_migrations, :version, length: 190, length: 190, unique: true

    add_index :oauth_applications, :uid, unique: true, length: 190
    add_index :oauth_applications, [:owner_id, :owner_type], length: {:owner_type => 180}

    add_index :oauth_access_tokens, :token, unique: true, length: 190
    add_index :oauth_access_tokens, :refresh_token, unique: true, length: 190
    add_index :oauth_access_tokens, :resource_owner_id

    add_index :oauth_access_grants, :token, unique: true, length: 190

    add_index :namespaces, :name, unique: true, length: 190
    add_index :namespaces, :path, unique: true, length: 190
    add_index :namespaces, :owner_id
    add_index :namespaces, :type, length: 190
    add_index :namespaces, [:created_at, :id]
    
    add_index :keys, :user_id
    add_index :keys, [:created_at, :id]

    add_index :emails, :email, unique: true, length: 190
    add_index :emails, :user_id



    ['web_hooks', 'users_star_projects', 'users', 'tags', 'taggings', 'subscriptions', 'snippets', 'services', 'schema_migrations', 'protected_branches', 'projects', 'oauth_applications', 'oauth_access_tokens', 'oauth_access_grants', 'notes', 'namespaces', 'milestones', 'merge_requests', 'merge_request_diffs', 'members', 'labels', 'label_links', 'keys', 'issues', 'identities', 'forked_project_links', 'events', 'emails', 'deploy_keys_projects', 'broadcast_messages', 'application_settings'].each do |table|
      execute "ALTER TABLE `#{table}` CONVERT TO character set utf8mb4 COLLATE utf8mb4_unicode_ci;"
    end
  end
  def down
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/
  end
end
