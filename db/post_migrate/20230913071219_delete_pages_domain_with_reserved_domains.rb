# frozen_string_literal: true

class DeletePagesDomainWithReservedDomains < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL.squish
      DELETE FROM "pages_domains"
      WHERE LOWER("pages_domains"."domain") IN
      ('aol.com', 'gmail.com', 'hotmail.co.uk', 'hotmail.com', 'hotmail.fr', 'icloud.com',
      'live.com', 'mail.com', 'me.com', 'msn.com', 'outlook.com', 'proton.me', 'protonmail.com',
      'tutanota.com', 'yahoo.com', 'yandex.com', 'zohomail.com');
    SQL
  end

  def down
    # no-op
    # This migration can't be rolled back as we are deleting entires
  end
end
