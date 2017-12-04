module HamlHelper
  # Backport of https://github.com/haml/haml/blob/master/lib/haml/helpers.rb#L585-L592
  # This method intentionally prefixed by `gl_` to prevent potentional name conflicts in the future.
  # This method should be removed once `haml` is updated to a version
  # where the `haml_tag_if` method is merged.
  #
  # Wrap data with tags if `condition` is true.
  # Data is always rendered (wether wrapped or not).
  def gl_haml_tag_if(condition, tag, classes)
    condition ? content_tag(tag, class: classes) { yield } : yield
  end
end
