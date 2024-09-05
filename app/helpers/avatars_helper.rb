# frozen_string_literal: true

module AvatarsHelper
  DEFAULT_AVATAR_PATH = 'no_avatar.png'

  def group_icon(group, options = {})
    source_icon(group, options)
  end

  def topic_icon(topic, options = {})
    source_icon(topic, options)
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

  def avatar_icon_for_email(email = nil, size = nil, scale = 2, only_path: true, by_commit_email: false)
    return default_avatar if email.blank?

    Gitlab::AvatarCache.by_email(email, size, scale, only_path) do
      avatar_icon_by_user_email_or_gravatar(
        email,
        size,
        scale,
        only_path: only_path,
        by_commit_email: by_commit_email
      )
    end
  end

  def avatar_icon_for_user(user = nil, size = nil, scale = 2, only_path: true, current_user: nil)
    return gravatar_icon(nil, size, scale) unless user
    return default_avatar if blocked_or_unconfirmed?(user) && !can_admin?(current_user)

    image_size = !size.nil? ? size * 2 : size

    user_avatar = user.avatar_url(size: image_size, only_path: only_path)
    user_avatar || default_avatar
  end

  def gravatar_icon(user_email = '', size = nil, scale = 2)
    GravatarService.new.execute(user_email, size, scale) ||
      default_avatar
  end

  def default_avatar
    ActionController::Base.helpers.image_path(DEFAULT_AVATAR_PATH)
  end

  def author_avatar(commit_or_event, options = {})
    options[:css_class] ||= "gl-hidden sm:gl-inline-block"

    if Feature.enabled?(:cached_author_avatar_helper, options.delete(:project))
      Gitlab::AvatarCache.by_email(commit_or_event.author_email, commit_or_event.author_name, options) do
        user_avatar(options.merge({
          user: commit_or_event.author,
          user_name: commit_or_event.author_name,
          user_email: commit_or_event.author_email
        }))
      end.html_safe # rubocop: disable Rails/OutputSafety -- this is only needed as the AvatarCache is a direct Redis cache
    else
      user_avatar(options.merge({
        user: commit_or_event.author,
        user_name: commit_or_event.author_name,
        user_email: commit_or_event.author_email
      }))
    end
  end

  def user_avatar(options = {})
    avatar = user_avatar_without_link(options)

    if options[:user]
      link_to(avatar, user_path(options[:user]))
    elsif options[:user_email]
      mail_to(options[:user_email], avatar)
    end
  end

  def user_avatar_without_link(options = {})
    avatar_size = options[:size] || 16
    user_name = options[:user].try(:name) || options[:user_name]

    avatar_url = user_avatar_url_for(**options.merge(size: avatar_size))

    has_tooltip = options[:has_tooltip].nil? ? true : options[:has_tooltip]
    data_attributes = options[:data] || {}
    css_class = %W[avatar s#{avatar_size}].push(*options[:css_class])
    alt_text = user_name ? "#{user_name}'s avatar" : "default avatar"

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
      alt: alt_text,
      src: avatar_url,
      data: data_attributes,
      class: css_class,
      title: user_name
    }

    tag.img(**image_options)
  end

  def avatar_without_link(resource, options = {})
    case resource
    when Namespaces::UserNamespace
      user_avatar_without_link(options.merge(user: resource.first_owner))
    when Group
      render Pajamas::AvatarComponent.new(resource, class: 'gl-avatar-circle gl-mr-3', size: 32)
    end
  end

  private

  def avatar_icon_by_user_email_or_gravatar(email, size, scale, only_path:, by_commit_email: false)
    user =
      if by_commit_email
        User.find_by_any_email(email)
      else
        User.with_public_email(email).first
      end

    if user
      avatar_icon_for_user(user, size, scale, only_path: only_path)
    else
      gravatar_icon(email, size, scale)
    end
  end

  def user_avatar_url_for(only_path: true, **options)
    return options[:url] if options[:url]
    return avatar_icon_for_user(options[:user], options[:size], only_path: only_path) if options[:user]

    avatar_icon_for_email(options[:user_email], options[:size], only_path: only_path)
  end

  def source_icon(source, options = {})
    avatar_url = source.try(:avatar_url)

    if avatar_url
      image_tag avatar_url, options
    else
      source_identicon(source, options)
    end

  rescue GRPC::Unavailable, GRPC::DeadlineExceeded => e
    # Handle Gitaly connection issues gracefully
    Gitlab::ErrorTracking
      .track_exception(e, source_type: source.class.name, source_id: source.id)

    source_identicon(source, options)
  end

  def source_identicon(source, options = {})
    bg_key = (source.id % 7) + 1
    size_class = "s#{options[:size]}" if options[:size]

    options[:class] =
      [*options[:class], "identicon bg#{bg_key}", size_class].compact.join(' ')

    content_tag(:span, class: options[:class].strip) do
      source.name[0, 1].upcase
    end
  end

  def blocked_or_unconfirmed?(user)
    user.blocked? || !user.confirmed?
  end

  def can_admin?(user)
    return false unless user

    user.can_admin_all_resources?
  end
end
