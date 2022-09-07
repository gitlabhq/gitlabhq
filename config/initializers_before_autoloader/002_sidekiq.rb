# frozen_string_literal: true

# Preloads Sidekiq configurations that don't require application references.
#
# It ensures default settings are loaded before any other file references
# (directly or indirectly) Sidekiq workers.
#

require 'sidekiq/web'

if Rails.env.development?
  Sidekiq.default_job_options[:backtrace] = true
end
