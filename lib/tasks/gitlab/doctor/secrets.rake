# frozen_string_literal: true

namespace :gitlab do
  namespace :doctor do
    desc "GitLab | Check if the database encrypted values can be decrypted using current secrets"
    task secrets: :gitlab_environment do
      logger = Logger.new($stdout)

      logger.level = Gitlab::Utils.to_boolean(ENV['VERBOSE']) ? Logger::DEBUG : Logger::INFO

      Gitlab::Doctor::Secrets.new(logger).run!
    end
  end
end
