# frozen_string_literal: true

require_relative '../../app/models/concerns/token_authenticatable'
require_relative '../../app/models/concerns/token_authenticatable_strategies/base'
require_relative '../../app/models/concerns/token_authenticatable_strategies/insecure'
require_relative '../../app/models/concerns/token_authenticatable_strategies/digest'

namespace :tokens do
  desc "Reset all GitLab incoming email tokens"
  task reset_all_email: :environment do
    reset_all_users_token(:reset_incoming_email_token!)
  end

  desc "Reset all GitLab feed tokens"
  task reset_all_feed: :environment do
    reset_all_users_token(:reset_feed_token!)
  end

  def reset_all_users_token(reset_token_method)
    TmpUser.find_in_batches do |batch|
      puts "Processing batch starting with user ID: #{batch.first.id}"
      $stdout.flush

      batch.each(&reset_token_method)
    end
  end
end

class TmpUser < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
  include TokenAuthenticatable

  self.table_name = 'users'

  add_authentication_token_field :incoming_email_token, token_generator: -> { SecureRandom.hex.to_i(16).to_s(36) }
  add_authentication_token_field :feed_token
end
