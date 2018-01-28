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

      options[:class] ||= ""
      options[:class] << " lazy"

      source = placeholder_image
    end

    super(source, options)
  end

  # Required for Banzai::Filter::ImageLazyLoadFilter
  module_function :placeholder_image
end
