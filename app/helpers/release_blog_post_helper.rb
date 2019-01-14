# frozen_string_literal: true

module ReleaseBlogPostHelper
  def blog_post_url
    Gitlab::ReleaseBlogPost.instance.blog_post_url
  end
end
