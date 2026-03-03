# frozen_string_literal: true

# Add IAM service proxy middleware to forward requests from /iam-service/* to the IAM service
# This allows GitLab to access IAM via HTTPS on the same host (gdk.test:3000)
# avoiding SSL verification issues when IAM runs on HTTP (localhost:8084)
#
# DEVELOPMENT ONLY: This middleware is only active in development environments.
Rails.application.config.middleware.use Gitlab::Middleware::IamServiceProxy if Rails.env.development?
