module JavascriptHelper
  def page_specific_javascript_tag(js)
    javascript_include_tag asset_path(js), { "data-turbolinks-track" => true }
  end
  def page_specific_javascript_bundle_tag(js)
    javascript_include_tag(*webpack_asset_paths(js), { "data-turbolinks-track" => true })
  end
end
