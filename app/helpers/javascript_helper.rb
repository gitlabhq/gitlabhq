module JavascriptHelper
  def page_specific_javascript_tag(js)
    javascript_include_tag asset_path(js)
  end
end
