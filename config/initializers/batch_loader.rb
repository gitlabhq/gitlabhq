# frozen_string_literal: true

Rails.application.config.middleware.use(BatchLoader::Middleware)
