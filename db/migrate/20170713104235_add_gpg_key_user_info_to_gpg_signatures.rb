# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGpgKeyUserInfoToGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :gpg_signatures, :gpg_key_user_name, :string
    add_column :gpg_signatures, :gpg_key_user_email, :string
  end
end
