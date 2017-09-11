# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddFilterToLdapGroupLinks < ActiveRecord::Migration
  def change
    add_column(:ldap_group_links, :filter, :string)
  end
end
