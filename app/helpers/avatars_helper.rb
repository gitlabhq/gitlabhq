module AvatarsHelper

  def author_avatar(commit_or_event, options = {})
    user_avatar(options.merge({
      user: commit_or_event.author,
      user_name: commit_or_event.author_name,
      user_email: commit_or_event.author_email,
    }))
  end

  private

  def user_avatar(options = {})
    avatar_size = options[:size] || 16
    user_name = options[:user].try(:name) || options[:user_name]
    avatar = image_tag(
      avatar_icon(options[:user] || options[:user_email], avatar_size),
      class: "avatar has-tooltip hidden-xs s#{avatar_size}",
      alt: "#{user_name}'s avatar",
      title: user_name
    )

    if options[:user]
      link_to(avatar, user_path(options[:user]))
    elsif options[:user_email]
      mail_to(options[:user_email], avatar)
    end
  end

end
