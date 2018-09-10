# frozen_string_literal: true

module LazyImageTagHelper
  def placeholder_image
    "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
  end

  # Override the default ActionView `image_tag` helper to support lazy-loading
  def image_tag(source, options = {})
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
end
