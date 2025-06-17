# frozen_string_literal: true

namespace :ci do
  desc 'CI | ID Tokens | Validate configuration for CI ID tokens with custom issuer URL'
  task validate_id_token_configuration: :environment do
    require_relative './validate_id_token_configuration_task'

    Tasks::Ci::ValidateIdTokenConfigurationTask.new.validate!
  end
end
