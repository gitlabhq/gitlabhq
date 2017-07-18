module JavascriptHelper
  def page_specific_javascript_tag(js)
    javascript_include_tag asset_path(js)
  end

  # deprecated; use webpack_bundle_tag directly instead
  def page_specific_javascript_bundle_tag(bundle)
    webpack_bundle_tag(bundle)
  end

  def repo_bundle_tags
    return unless body_data_page =~ /projects\:(tree|blob)\:show/

    webpack_bundle_tag('repo')
  end
end
