# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ApplySecurityPoliciesDescriptionTextLimit < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_text_limit :security_policies, :description, 1_000_000
  end

  def down
    remove_text_limit :security_policies, :description
  end
end
