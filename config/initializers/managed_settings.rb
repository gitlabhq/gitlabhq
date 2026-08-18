# frozen_string_literal: true

# Persist configuration-managed application settings into the database on boot. Runs after
# initialization so the database connection is ready; the method is a no-op when the feature
# is disabled or the database is not available (for example, pending migrations).
Rails.application.config.after_initialize do
  Gitlab::ManagedSettings.apply!
end
