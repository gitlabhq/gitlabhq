# frozen_string_literal: true

module MergeRequests
  class SavedViewPolicy < BasePolicy
    desc 'The saved view belongs to the current user'
    condition(:belongs_to_user, score: 0) { @user.is_a?(User) && @subject.user_id == @user.id }

    rule { anonymous }.prevent_all

    rule { belongs_to_user }.policy do
      enable :read_saved_view
      enable :update_saved_view
      enable :delete_saved_view
    end
  end
end
