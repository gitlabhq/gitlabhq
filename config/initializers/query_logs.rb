# frozen_string_literal: true

# ActiveRecord::QueryLogs annotates SQL queries with runtime context. It is
# enabled in config/application.rb; the tags themselves live in
# Gitlab::QueryLogs.
#
# See: https://api.rubyonrails.org/classes/ActiveRecord/QueryLogs.html

# By default, PostgreSQL only tracks the first 1024 bytes of a SQL
# query. Prepending the comment allows us to trace the source of the
# query without having to increase the `track_activity_query_size`
# parameter.
#
# We only enable this in production because a number of tests do string
# matching against the raw SQL, and prepending the comment prevents color
# coding from working in the development log.
ActiveRecord::QueryLogs.prepend_comment = true if Rails.env.production?

# The tags have to be assigned after initialization: the Action Controller and
# Active Job railties append `:controller`, `:action` and `:job` to
# `config.active_record.query_log_tags`, which the Active Record railtie then
# copies into `ActiveRecord::QueryLogs.tags` from its own `after_initialize`
# hook. Assigning here, once that hook has run, keeps the tag list under our
# control. `endpoint_id` already covers controller, action and worker name.
Rails.application.config.after_initialize do
  ActiveRecord::QueryLogs.tags = Gitlab::QueryLogs.tags
end
