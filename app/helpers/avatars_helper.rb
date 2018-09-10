# frozen_string_literal: true

module AvatarsHelper
  def project_icon(project_id, options = {})
    source_icon(Project, project_id, options)
  end

  def group_icon(group_id, options = {})
    source_icon(Group, group_id, options)
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
      css_class: 'd-none d-sm-inline'
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

  private

  def source_icon(klass, source_id, options = {})
    source =
      if source_id.respond_to?(:avatar_url)
        source_id
      else
        klass.find_by_full_path(source_id)
      end

    if source.avatar_url
      image_tag source.avatar_url, options
    else
      source_identicon(source, options)
    end
  end

  def source_identicon(source, options = {})
    bg_key = (source.id % 7) + 1

    options[:class] =
      [*options[:class], "identicon bg#{bg_key}"].join(' ')

    content_tag(:div, class: options[:class].strip) do
      source.name[0, 1].upcase
    end
  end
end
