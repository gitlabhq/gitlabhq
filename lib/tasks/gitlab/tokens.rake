# frozen_string_literal: true

require_relative 'tokens/manage_expiry_task'

namespace :gitlab do
  namespace :tokens do
    desc 'GitLab | Tokens | Show information about tokens'
    task analyze: :environment do |_t, _args|
      Tasks::Gitlab::Tokens::ManageExpiryTask.new.analyze
    end

    desc 'GitLab | Tokens | Edit expiration dates for tokens'
    task edit: :environment do |_t, _args|
      Tasks::Gitlab::Tokens::ManageExpiryTask.new.edit
    end
  end
end
