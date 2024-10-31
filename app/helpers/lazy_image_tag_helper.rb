# frozen_string_literal: true

module LazyImageTagHelper
  include PreferencesHelper

  def placeholder_image
    "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
  end

  # Override the default ActionView `image_tag` helper to support lazy-loading
  # accept :auto_dark boolean to enable automatic dark variant of the image
  # (see: https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/2698)
  # accept :dark_variant path to be used as a source when dark mode is enabled
  def image_tag(source, options = {})
    source, options = prepare_dark_variant(source, options)
    options = options.symbolize_keys

    unless options.delete(:lazy) == false
      options[:data] ||= {}
      options[:data][:src] = path_to_image(source)

      # options[:class] can be either String or Array.
      klass_opts = Array.wrap(options[:class])
      klass_opts << "lazy"

      options[:class] = klass_opts.join(' ')
      source = placeholder_image
    end

    super(source, options)
  end

  # Required for Banzai::Filter::ImageLazyLoadFilter
  module_function :placeholder_image

  private

  def prepare_dark_variant(source, options)
    dark_variant = options.delete(:dark_variant)
    auto_dark = options.delete(:auto_dark)

    raise ArgumentError, "dark_variant and auto_dark are mutually exclusive" if dark_variant && auto_dark

    if (auto_dark || dark_variant) && user_application_dark_mode?
      if auto_dark
        options[:class] = 'gl-dark-invert-keep-hue'
      elsif dark_variant
        source = dark_variant
      end
    end

    [source, options]
  end
end
