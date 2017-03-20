module PipelinesHelper
  def pipeline_user_avatar(pipeline)
    user_avatar(user: pipeline.user, size: 24)
  end

  def pipeline_user_link(pipeline)
    link_to(pipeline.user.name, user_path(pipeline.user),
            title: pipeline.user.email,
            class: 'has-tooltip commit-committer-link')
  end
end
