# frozen_string_literal: true

namespace :gitlab do
  namespace :doctor do
    desc "GitLab | Check if the database encrypted values can be decrypted using current secrets"
    task secrets: :gitlab_environment do
      logger = Logger.new($stdout)

      logger.level = Gitlab::Utils.to_boolean(ENV['VERBOSE']) ? Logger::DEBUG : Logger::INFO

      Gitlab::Doctor::Secrets.new(logger).run!
    end

    desc "GitLab | Reset encrypted tokens for specific models"
    task reset_encrypted_tokens: :gitlab_environment do
      logger = Logger.new($stdout)

      logger.level = Gitlab::Utils.to_boolean(ENV['VERBOSE']) ? Logger::DEBUG : Logger::INFO
      model_names = ENV['MODEL_NAMES']&.split(',')
      token_names = ENV['TOKEN_NAMES']&.split(',')
      dry_run = Gitlab::Utils.to_boolean(ENV['DRY_RUN'])
      dry_run = true if dry_run.nil?

      next logger.info("No models were specified, please use MODEL_NAMES environment variable") unless model_names
      next logger.info("No tokens were specified, please use TOKEN_NAMES environment variable") unless token_names

      Gitlab::Doctor::ResetTokens.new(logger, model_names: model_names, token_names: token_names, dry_run: dry_run).run!
    end
  end
end
