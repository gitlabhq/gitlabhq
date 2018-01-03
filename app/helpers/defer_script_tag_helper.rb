module DeferScriptTagHelper
  # Override the default ActionView `javascript_include_tag` helper to support page specific deferred loading
  def javascript_include_tag(*sources)
    super(*sources, defer: true)
  end
end
