# frozen_string_literal: true

class BackfillSignInPathToProtectedPaths < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  NEW_PATH = '/users/sign_in_path'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET protected_paths_for_get_request = array_append(protected_paths_for_get_request, '#{NEW_PATH}')
      WHERE NOT (protected_paths_for_get_request @> ARRAY['#{NEW_PATH}']::text[])
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET protected_paths_for_get_request = array_remove(protected_paths_for_get_request, '#{NEW_PATH}')
    SQL
  end
end
