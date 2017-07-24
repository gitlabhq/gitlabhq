module SafeMirrorParams
  extend ActiveSupport::Concern

  included do
    helper_method :default_mirror_users
  end

  private

  def valid_mirror_user?(mirror_params)
    return true unless mirror_params[:mirror_user_id].present?

    default_mirror_users.map(&:id).include?(mirror_params[:mirror_user_id].to_i)
  end

  def default_mirror_users
    [current_user, @project.mirror_user].compact.uniq
  end
end
