module JavascriptHelper
  def page_specific_javascripts(js = nil)
    @page_specific_javascripts = js unless js.nil?

    @page_specific_javascripts
  end
end
