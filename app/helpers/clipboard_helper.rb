module ClipboardHelper
  def clipboard_button
    content_tag :button,
      icon('clipboard'),
      class: 'btn btn-xs btn-clipboard js-clipboard-trigger',
      type: :button
  end
end
