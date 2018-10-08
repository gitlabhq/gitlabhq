module BatchCommentsHelper
  def batch_comments_enabled?
    current_user.present? && @project.feature_available?(:batch_comments, current_user)
  end
end
