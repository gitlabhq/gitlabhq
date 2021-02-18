# frozen_string_literal: true

# This middleware has to come after Gitlab::Metrics::RackMiddleware
# in the middleware stack, because it tracks events with
# GitLab Performance Monitoring
Rails.application.config.middleware.use(Gitlab::EtagCaching::Middleware)
