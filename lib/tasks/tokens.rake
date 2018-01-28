require_relative '../../app/models/concerns/token_authenticatable.rb'

namespace :tokens do
  desc "Reset all GitLab incoming email tokens"
  task reset_all_email: :environment do
    reset_all_users_token(:reset_incoming_email_token!)
  end

  desc "Reset all GitLab RSS tokens"
  task reset_all_rss: :environment do
    reset_all_users_token(:reset_rss_token!)
  end

  def reset_all_users_token(reset_token_method)
    TmpUser.find_in_batches do |batch|
      puts "Processing batch starting with user ID: #{batch.first.id}"
      STDOUT.flush

      batch.each(&reset_token_method)
    end
  end
end

class TmpUser < ActiveRecord::Base
  include TokenAuthenticatable

  self.table_name = 'users'

  def reset_incoming_email_token!
    write_new_token(:incoming_email_token)
    save!(validate: false)
  end

  def reset_rss_token!
    write_new_token(:rss_token)
    save!(validate: false)
  end
end
