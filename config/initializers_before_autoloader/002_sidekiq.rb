# frozen_string_literal: true

# Preloads Sidekiq configurations that don't require application references.
#
# It ensures default settings are loaded before any other file references
# (directly or indirectly) Sidekiq workers.
#

require 'sidekiq/web'

# Disable the Sidekiq Rack session since GitLab already has its own session store.
# CSRF protection still works (https://github.com/mperham/sidekiq/commit/315504e766c4fd88a29b7772169060afc4c40329).
Sidekiq::Web.set :sessions, false

if Rails.env.development?
  Sidekiq.default_worker_options[:backtrace] = true
end
