# frozen_string_literal: true

class AddSignInPathToProtectedPathsDefault < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  OLD_GET_REQUEST_DEFAULT = [].freeze

  NEW_GET_REQUEST_DEFAULT = %w[
    /users/sign_in_path
  ].freeze

  def change
    change_column_default(
      :application_settings,
      :protected_paths_for_get_request,
      from: OLD_GET_REQUEST_DEFAULT,
      to: NEW_GET_REQUEST_DEFAULT
    )
  end
end
