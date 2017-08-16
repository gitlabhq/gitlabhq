# This model is used to replicate events between the old "events" table and the
# new "events_for_migration" table that will replace "events" in GitLab 10.0.
class EventForMigration < ActiveRecord::Base
  self.table_name = 'events_for_migration'
end
