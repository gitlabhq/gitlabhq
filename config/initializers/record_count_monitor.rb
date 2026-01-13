# frozen_string_literal: true

Gitlab::Database::RecordCountMonitor.subscribe if Rails.env.development?
