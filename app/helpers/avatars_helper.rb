module AvatarsHelper
  def project_icon(project_id, options = {})
    project =
      if project_id.respond_to?(:avatar_url)
        project_id
      else
        Project.find_by_full_path(project_id)
      end

    if project.avatar_url
      image_tag project.avatar_url, options
    else # generated icon
      project_identicon(project, options)
    end
  end

  def project_identicon(project, options = {})
    allowed_colors = {
      red: 'FFEBEE',
      purple: 'F3E5F5',
      indigo: 'E8EAF6',
      blue: 'E3F2FD',
      teal: 'E0F2F1',
      orange: 'FBE9E7',
      gray: 'EEEEEE'
    }

    options[:class] ||= ''
    options[:class] << ' identicon'
    bg_key = project.id % 7
    style = "background-color: ##{allowed_colors.values[bg_key]}; color: #555"

    content_tag(:div, class: options[:class], style: style) do
      project.name[0, 1].upcase
    end
  end

  # Takes both user and email and returns the avatar_icon by
  # user (preferred) or email.
  def avatar_icon_for(user = nil, email = nil, size = nil, scale = 2, only_path: true)
    if user
      avatar_icon_for_user(user, size, scale, only_path: only_path)
    elsif email
      avatar_icon_for_email(email, size, scale, only_path: only_path)
    else
      default_avatar
    end
  end

  def avatar_icon_for_email(email = nil, size = nil, scale = 2, only_path: true)
    user = User.find_by_any_email(email.try(:downcase))
    if user
      avatar_icon_for_user(user, size, scale, only_path: only_path)
    else
      gravatar_icon(email, size, scale)
    end
  end

  def avatar_icon_for_user(user = nil, size = nil, scale = 2, only_path: true)
    if user
      user.avatar_url(size: size, only_path: only_path) || default_avatar
    else
      gravatar_icon(nil, size, scale)
    end
  end

  def gravatar_icon(user_email = '', size = nil, scale = 2)
    GravatarService.new.execute(user_email, size, scale) ||
      default_avatar
  end

  def default_avatar
    ActionController::Base.helpers.image_path('no_avatar.png')
  end

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
