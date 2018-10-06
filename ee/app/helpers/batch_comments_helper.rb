module BatchCommentsHelper
  def batch_comments_enabled?
    current_user.present? && License.feature_available?(:batch_comments) && Feature.enabled?(:batch_comments, current_user, default_enabled: false)
  end
end
