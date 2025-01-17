# frozen_string_literal: true

require 'json'

module IconsHelper
  extend self

  DEFAULT_ICON_SIZE = 16

  VARIANT_CLASSES = {
    current: 'gl-fill-current',
    default: 'gl-fill-icon-default',
    subtle: 'gl-fill-icon-subtle',
    strong: 'gl-fill-icon-strong',
    disabled: 'gl-fill-icon-disabled',
    link: 'gl-fill-icon-link',
    info: 'gl-fill-icon-info',
    warning: 'gl-fill-icon-warning',
    danger: 'gl-fill-icon-danger',
    success: 'gl-fill-icon-success'
  }.freeze

  def custom_icon(icon_name, size: DEFAULT_ICON_SIZE)
    memoized_icon("#{icon_name}_#{size}") do
      render partial: "shared/icons/#{icon_name}", formats: :svg, locals: { size: size }
    end
  end

  def sprite_icon_path
    @sprite_icon_path ||= begin
      # SVG Sprites currently don't work across domains, so in the case of a CDN
      # we have to set the current path deliberately to prevent addition of asset_host
      sprite_base_url = Gitlab.config.gitlab.url if ActionController::Base.asset_host
      ActionController::Base.helpers.image_path('icons.svg', host: sprite_base_url)
    end
  end

  def sprite_file_icons_path
    # SVG Sprites currently don't work across domains, so in the case of a CDN
    # we have to set the current path deliberately to prevent addition of asset_host
    sprite_base_url = Gitlab.config.gitlab.url if ActionController::Base.asset_host
    ActionController::Base.helpers.image_path('file_icons/file_icons.svg', host: sprite_base_url)
  end

  def sprite_icon(icon_name, size: DEFAULT_ICON_SIZE, css_class: nil, file_icon: false, aria_label: nil, variant: nil)
    memoized_icon("#{icon_name}_#{size}_#{css_class}_#{variant}") do
      unknown_icon = file_icon ? unknown_file_icon_sprite(icon_name) : unknown_icon_sprite(icon_name)
      if unknown_icon
        exception = ArgumentError.new("#{icon_name} is not a known icon in @gitlab-org/gitlab-svg")
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception)
      end

      css_classes = []
      css_classes << "s#{size}" if size
      css_classes << VARIANT_CLASSES[variant&.to_sym]
      css_classes << css_class.to_s unless css_class.blank?
      css_classes.compact!

      sprite_path = file_icon ? sprite_file_icons_path : sprite_icon_path

      content_tag(
        :svg,
        content_tag(:use, '', { 'href' => "#{sprite_path}##{icon_name}" }),
        class: css_classes.empty? ? nil : css_classes.join(' '),
        data: { testid: "#{icon_name}-icon" },
        'aria-label': aria_label
      )
    end
  end

  # Creates a GitLab UI loading icon/spinner.
  #
  # Examples:
  #   # Default
  #   gl_loading_icon
  #
  #   # Sizes
  #   gl_loading_icon(size: 'md')
  #   gl_loading_icon(size: 'lg')
  #   gl_loading_icon(size: 'xl')
  #
  #   # Colors
  #   gl_loading_icon(color: 'light')
  #
  #   # Block/Inline
  #   gl_loading_icon(inline: true)
  #
  #   # Custom classes
  #   gl_loading_icon(css_class: "foo-bar")
  #
  # See also https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-loading-icon--default
  def gl_loading_icon(inline: false, color: 'dark', size: 'sm', css_class: nil, data: nil)
    render Pajamas::SpinnerComponent.new(
      inline: inline,
      color: color,
      size: size,
      class: css_class,
      data: data
    )
  end

  def external_snippet_icon(name)
    content_tag(:span, "", class: "gl-snippet-icon gl-snippet-icon-#{name}") # rubocop:disable Tailwind/StringInterpolation -- Not a CSS utility class
  end

  def audit_icon(name, css_class: nil)
    case name
    when "standard"
      name = "key"
    when "two-factor"
      name = "key"
    when "google_oauth2"
      name = "google"
    end

    sprite_icon(name, css_class: css_class)
  end

  def boolean_to_icon(value)
    if value
      sprite_icon('check',
        css_class: 'gl-text-success') + content_tag(:span, _('Enabled'), class: 'gl-pl-2 gl-text-subtle')
    else
      content_tag(:span, _('Not enabled'), class: 'gl-text-subtle')
    end
  end

  def visibility_level_icon(level, options: {})
    name =
      case level
      when Gitlab::VisibilityLevel::PRIVATE
        'lock'
      when Gitlab::VisibilityLevel::INTERNAL
        'shield'
      else # Gitlab::VisibilityLevel::PUBLIC
        'earth'
      end

    css_class = options.delete(:class)

    sprite_icon(name, size: DEFAULT_ICON_SIZE, css_class: css_class)
  end

  def file_type_icon_class(type, mode, name)
    if type == 'folder'
      'folder'
    elsif type == 'archive'
      'archive'
    elsif mode == '120000'
      'share'
    else
      # Guess which icon to choose based on file extension.
      # If you think a file extension is missing, feel free to add it on PR

      case File.extname(name).downcase
      when '.pdf'
        'document'
      when '.jpg', '.jpeg', '.jif', '.jfif',
           '.jp2', '.jpx', '.j2k', '.j2c',
           '.apng', '.png', '.gif', '.tif', '.tiff',
           '.svg', '.ico', '.bmp', '.webp'
        'doc-image'
      when '.zip', '.zipx', '.tar', '.gz', '.gzip', '.tgz', '.bz', '.bzip',
           '.bz2', '.bzip2', '.car', '.tbz', '.xz', 'txz', '.rar', '.7z',
           '.lz', '.lzma', '.tlz'
        'doc-compressed'
      when '.mp3', '.wma', '.ogg', '.oga', '.wav', '.flac', '.aac', '.3ga',
           '.ac3', '.midi', '.m4a', '.ape', '.mpa'
        'volume-up'
      when '.mp4', '.m4p', '.m4v',
           '.mpg', '.mp2', '.mpeg', '.mpe', '.mpv',
           '.mpg', '.mpeg', '.m2v', '.m2ts',
           '.avi', '.mkv', '.flv', '.ogv', '.mov',
           '.3gp', '.3g2'
        'live-preview'
      when '.doc', '.dot', '.docx', '.docm', '.dotx', '.dotm', '.docb',
           '.odt', '.ott', '.uot', '.rtf'
        'doc-text'
      when '.xls', '.xlt', '.xlm', '.xlsx', '.xlsm', '.xltx', '.xltm',
           '.xlsb', '.xla', '.xlam', '.xll', '.xlw', '.ots', '.ods', '.uos'
        'document'
      when '.ppt', '.pot', '.pps', '.pptx', '.pptm', '.potx', '.potm',
           '.ppam', '.ppsx', '.ppsm', '.sldx', '.sldm', '.odp', '.otp', '.uop'
        'doc-chart'
      else
        'doc-text'
      end
    end
  end

  private

  def unknown_icon_sprite(icon_name)
    known_sprites&.exclude?(icon_name)
  end

  def unknown_file_icon_sprite(icon_name)
    known_file_icon_sprites&.exclude?(icon_name)
  end

  def known_sprites
    return if Rails.env.production?

    @known_sprites ||= parse_sprite_definition('icons.json')['icons']
  end

  def known_file_icon_sprites
    return if Rails.env.production?

    @known_file_icon_sprites ||= parse_sprite_definition('file_icons/file_icons.json')['icons']
  end

  def parse_sprite_definition(sprite_definition)
    Gitlab::Json.parse(
      Rails.application
           .assets_manifest
           .find_sources(sprite_definition)
           .first
           .to_s
           .force_encoding('UTF-8')
    )
  end

  def memoized_icon(key)
    @rendered_icons ||= {}

    @rendered_icons[key] || (
      @rendered_icons[key] = yield
    )
  end
end
