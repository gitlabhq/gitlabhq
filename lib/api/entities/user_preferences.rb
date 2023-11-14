# frozen_string_literal: true

module API
  module Entities
    class UserPreferences < Grape::Entity
      expose :id, :user_id, :view_diffs_file_by_file,
        :show_whitespace_in_diffs, :pass_user_identities_to_ci_jwt
    end
  end
end

API::Entities::UserPreferences.prepend_mod_with('API::Entities::UserPreferences', with_descendants: true)
