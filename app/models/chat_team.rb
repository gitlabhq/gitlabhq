# frozen_string_literal: true

class ChatTeam < ApplicationRecord
  validates :team_id, presence: true
  validates :namespace, uniqueness: true

  belongs_to :namespace

  def remove_mattermost_team(current_user)
    ::Mattermost::Team.new(current_user).destroy(team_id: team_id)
  rescue ::Mattermost::ClientError => e
    # Either the group is not found, or the user doesn't have the proper
    # access on the mattermost instance. In the first case, we're done either way
    # in the latter case, we can't recover by retrying, so we just log what happened
    Gitlab::AppLogger.error("Mattermost team deletion failed: #{e}")
  end
end
