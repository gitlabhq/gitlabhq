# frozen_string_literal: true

module BadgesHelper
  VARIANT_CLASSES = {
    muted: "badge-muted",
    neutral: "badge-neutral",
    info: "badge-info",
    success: "badge-success",
    warning: "badge-warning",
    danger: "badge-danger"
  }.tap { |hash| hash.default = hash.fetch(:muted) }.freeze

  SIZE_CLASSES = {
    sm: "sm",
    md: "md",
    lg: "lg"
  }.tap { |hash| hash.default = hash.fetch(:md) }.freeze

  GL_BADGE_CLASSES = %w[gl-badge badge badge-pill].freeze

  GL_ICON_CLASSES = %w[gl-icon gl-badge-icon].freeze

  # Creates a GitLab UI badge.
  #
  # Examples:
  #   # Plain text badge
  #   gl_badge_tag("foo")
  #
  #   # Danger variant
  #   gl_badge_tag("foo", variant: :danger)
  #
  #   # Small size
  #   gl_badge_tag("foo", size: :sm)
  #
  #   # With icon
  #   gl_badge_tag("foo", icon: "question-o")
  #
  #   # Icon-only
  #   gl_badge_tag("foo", icon: "question-o", icon_only: true)
  #
  #   # Badge link
  #   gl_badge_tag("foo", nil, href: some_path)
  #
  #   # Custom classes
  #   gl_badge_tag("foo", nil, class: "foo-bar")
  #
  #   # Block content
  #   gl_badge_tag({ variant: :danger }, { class: "foo-bar" }) do
  #     "foo"
  #   end
  #
  # For accessibility, ensure that the given text or block is non-empty.
  #
  # See also https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-badge--default.
  def gl_badge_tag(*args, &block)
    if block_given?
      build_gl_badge_tag(capture(&block), *args)
    else
      build_gl_badge_tag(*args)
    end
  end

  private

  def build_gl_badge_tag(content, options = nil, html_options = nil)
    options ||= {}
    html_options ||= {}

    icon_only = options[:icon_only]
    variant_class = VARIANT_CLASSES[options.fetch(:variant, :muted)]
    size_class = SIZE_CLASSES[options.fetch(:size, :md)]
    icon_classes = GL_ICON_CLASSES.dup << options.fetch(:icon_classes, nil)

    html_options = html_options.merge(
      class: [
        *GL_BADGE_CLASSES,
        variant_class,
        size_class,
        *html_options[:class]
      ]
    )

    if icon_only
      html_options['aria-label'] = content
      html_options['role'] = 'img'
    end

    if options[:icon]
      icon_classes << "gl-mr-2" unless icon_only
      icon = sprite_icon(options[:icon], css_class: icon_classes.join(' '))

      content = icon_only ? icon : icon + content
    end

    tag = html_options[:href].nil? ? :span : :a

    content_tag(tag, content, html_options)
  end
end
