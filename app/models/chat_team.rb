# frozen_string_literal: true

class ChatTeam < ApplicationRecord
  validates :team_id, presence: true
  validates :namespace, uniqueness: true

  belongs_to :namespace

  def remove_mattermost_team(current_user)
    ::Mattermost::Team.new(current_user).destroy(team_id: team_id)
  rescue ::Mattermost::Error, Gitlab::HTTP::BlockedUrlError => e
    # Rescue all Mattermost errors (ClientError, ConnectionError, NoSessionError)
    # and blocked URL errors (e.g. when Mattermost is no longer reachable or has
    # been removed from the instance). In all these cases we can't recover by
    # retrying, so we log what happened and allow group deletion to continue.
    Gitlab::AppLogger.warn(
      message: "Mattermost team deletion failed, proceeding with group deletion",
      team_id: team_id,
      Labkit::Fields::ERROR_TYPE => e.class.name,
      Labkit::Fields::ERROR_MESSAGE => e.message
    )
  end
end
