module JavascriptHelper
  def page_specific_javascript_tag(js)
    javascript_include_tag asset_path(js)
  end

  # deprecated; use webpack_bundle_tag directly instead
  def page_specific_javascript_bundle_tag(bundle, opts = {})
    webpack_bundle_tag(bundle, opts)
  end
end
