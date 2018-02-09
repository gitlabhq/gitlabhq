module AvatarsHelper
  def author_avatar(commit_or_event, options = {})
    user_avatar(options.merge({
      user: commit_or_event.author,
      user_name: commit_or_event.author_name,
      user_email: commit_or_event.author_email,
      css_class: 'hidden-xs'
    }))
  end

  def user_avatar_url_for(options = {})
    if options[:url]
      options[:url]
    elsif options[:user]
      avatar_icon_for_user(options[:user], options[:size])
    else
      avatar_icon_for_email(options[:user_email], options[:size])
    end
  end

  def user_avatar_without_link(options = {})
    avatar_size = options[:size] || 16
    user_name = options[:user].try(:name) || options[:user_name]

    avatar_url = user_avatar_url_for(options.merge(size: avatar_size))

    has_tooltip = options[:has_tooltip].nil? ? true : options[:has_tooltip]
    data_attributes = options[:data] || {}
    css_class = %W[avatar s#{avatar_size}].push(*options[:css_class])

    if has_tooltip
      css_class.push('has-tooltip')
      data_attributes[:container] = 'body'
    end

    if options[:lazy]
      css_class << 'lazy'
      data_attributes[:src] = avatar_url
      avatar_url = LazyImageTagHelper.placeholder_image
    end

    image_options = {
      alt:   "#{user_name}'s avatar",
      src:   avatar_url,
      data:  data_attributes,
      class: css_class,
      title: user_name
    }

    tag(:img, image_options)
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
