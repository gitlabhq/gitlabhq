module GhostUser
  extend ActiveSupport::Concern

  def ghost_user?
    user && user.ghost?
  end
end
