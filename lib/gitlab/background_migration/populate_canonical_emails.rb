# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class to populate new rows of UserCanonicalEmail based on existing email addresses
    class PopulateCanonicalEmails
      def perform(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO
            user_canonical_emails (
                user_id,
                canonical_email,
                created_at,
                updated_at
            )
            SELECT users.id AS user_id,
                   concat(translate(split_part(split_part(users.email, '@', 1), '+', 1), '.', ''), '@gmail.com') AS canonical_email,
                   NOW() AS created_at,
                   NOW() AS updated_at
             FROM users
            WHERE users.email ILIKE '%@gmail.com'
              AND users.id BETWEEN #{start_id} AND #{stop_id}
            ON CONFLICT DO NOTHING;
        SQL
      end
    end
  end
end
