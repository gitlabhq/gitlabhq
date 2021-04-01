# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class WrongfullyConfirmedEmailUnconfirmer
      class UserModel < ActiveRecord::Base
        alias_method :reset, :reload

        self.table_name = 'users'

        scope :active, -> { where(state: 'active', user_type: nil) } # only humans, skip bots

        devise :confirmable
      end

      class EmailModel < ActiveRecord::Base
        alias_method :reset, :reload

        self.table_name = 'emails'

        belongs_to :user

        devise :confirmable

        def self.wrongfully_confirmed_emails(start_id, stop_id)
          joins(:user)
            .merge(UserModel.active)
            .where(id: (start_id..stop_id))
            .where.not('emails.confirmed_at' => nil)
            .where('emails.confirmed_at = users.confirmed_at')
            .where('emails.email <> users.email')
            .where('NOT EXISTS (SELECT 1 FROM user_synced_attributes_metadata WHERE user_id=users.id AND email_synced IS true)')
        end
      end

      def perform(start_id, stop_id)
        email_records = EmailModel
          .wrongfully_confirmed_emails(start_id, stop_id)
          .to_a

        user_ids = email_records.map(&:user_id).uniq

        ActiveRecord::Base.transaction do
          update_email_records(start_id, stop_id)
          update_user_records(user_ids)
        end

        # Refind the records with the "real" Email model so devise will notice that the user / email is unconfirmed
        unconfirmed_email_records = ::Email.where(id: email_records.map(&:id))
        ActiveRecord::Associations::Preloader.new.preload(unconfirmed_email_records, [:user])

        send_emails(unconfirmed_email_records)
      end

      private

      def update_email_records(start_id, stop_id)
        EmailModel.connection.execute <<-SQL
          WITH md5_strings as #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            #{email_query_for_update(start_id, stop_id).to_sql}
          )
          UPDATE #{EmailModel.connection.quote_table_name(EmailModel.table_name)}
          SET confirmed_at = NULL,
            confirmation_token = md5_strings.md5_string,
            confirmation_sent_at = NOW()
          FROM md5_strings
          WHERE id = md5_strings.email_id
        SQL
      end

      def update_user_records(user_ids)
        UserModel
          .where(id: user_ids)
          .update_all("confirmed_at = NULL, confirmation_sent_at = NOW(), unconfirmed_email = NULL, confirmation_token=md5(users.id::varchar || users.created_at || users.encrypted_password || '#{Integer(Time.now.to_i)}')")
      end

      def email_query_for_update(start_id, stop_id)
        EmailModel
          .wrongfully_confirmed_emails(start_id, stop_id)
          .select('emails.id as email_id', "md5(emails.id::varchar || emails.created_at || users.encrypted_password || '#{Integer(Time.now.to_i)}') as md5_string")
      end

      def send_emails(email_records)
        user_records = email_records.map(&:user).uniq

        user_records.each do |user|
          Gitlab::BackgroundMigration::Mailers::UnconfirmMailer.unconfirm_notification_email(user).deliver_later
          DeviseMailer.confirmation_instructions(user, user.confirmation_token).deliver_later(wait: 1.minute)
        end

        email_records.each do |email|
          DeviseMailer.confirmation_instructions(email, email.confirmation_token).deliver_later(wait: 1.minute)
        end
      end
    end
  end
end
