module AvatarsHelper
  def author_avatar(commit_or_event, options = {})
    user_avatar(options.merge({
      user: commit_or_event.author,
      user_name: commit_or_event.author_name,
      user_email: commit_or_event.author_email,
      css_class: 'hidden-xs'
    }))
  end

  def user_avatar_without_link(options = {})
    avatar_size = options[:size] || 16
    user_name = options[:user].try(:name) || options[:user_name]
    avatar_url = options[:url] || avatar_icon(options[:user] || options[:user_email], avatar_size)
    has_tooltip = options[:has_tooltip].nil? ? true : options[:has_tooltip]
    data_attributes = {}
    css_class = %W[avatar s#{avatar_size}].push(*options[:css_class])

    if has_tooltip
      css_class.push('has-tooltip')
      data_attributes = { container: 'body' }
    end

    image_tag(
      avatar_url,
      class: css_class,
      alt: "#{user_name}'s avatar",
      title: user_name,
      data: data_attributes,
      lazy: true
    )
  end

  def user_avatar(options = {})
    avatar = user_avatar_without_link(options)

    if options[:user]
      link_to(avatar, user_path(options[:user]))
    elsif options[:user_email]
      mail_to(options[:user_email], avatar)
    end
  end
end
