module WikisHelper
  def markdown_to_html(text)
    RDiscount.new(text).to_html.html_safe
  end
end
