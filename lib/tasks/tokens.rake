# frozen_string_literal: true

namespace :tokens do
  require_relative '../../app/models/concerns/token_authenticatable'
  require_relative '../../lib/authn/token_field/base'
  require_relative '../../lib/authn/token_field/insecure'
  require_relative '../../lib/authn/token_field/digest'

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

  add_authentication_token_field :incoming_email_token, # rubocop:disable Gitlab/TokenWithoutPrefix -- prefix is assigned in token generator
    token_generator: -> { User.generate_incoming_mail_token }
  add_authentication_token_field :feed_token, format_with_prefix: :prefix_for_feed_token

  def prefix_for_feed_token
    User::FEED_TOKEN_PREFIX
  end
end
