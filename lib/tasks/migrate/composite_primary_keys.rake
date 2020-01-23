namespace :gitlab do
  namespace :db do
    desc 'GitLab | DB | Adds primary keys to tables that only have composite unique keys'
    task composite_primary_keys_add: :environment do
      require Rails.root.join('db/optional_migrations/composite_primary_keys')
      CompositePrimaryKeysMigration.new.up
    end

    desc 'GitLab | DB | Removes previously added composite primary keys'
    task composite_primary_keys_drop: :environment do
      require Rails.root.join('db/optional_migrations/composite_primary_keys')
      CompositePrimaryKeysMigration.new.down
    end
  end
end
