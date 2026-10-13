# frozen_string_literal: true

module Import
  class SourceUserPolicy < ::BasePolicy
    desc "User can administrate namespace"
    condition(:admin_source_user_namespace) { can?(:admin_namespace, @subject.namespace) }

    desc "User is the user contributions were reassigned to and the reassignment is completed or revoked"
    condition(:reassign_to_user, score: 0) do
      @user && @subject.reassign_to_user_id == @user.id && (@subject.completed? || @subject.revoked?)
    end

    rule { admin_source_user_namespace }.policy do
      enable :admin_import_source_user
    end

    rule { admin_source_user_namespace | reassign_to_user }.policy do
      enable :read_import_source_user
    end

    rule { reassign_to_user }.policy do
      enable :revoke_placeholder_reassignment
    end
  end
end
