module IconsHelper
  def boolean_to_icon(value)
    if value.to_s == "true"
      content_tag :i, nil, class: 'icon-ok cgreen'
    else
      content_tag :i, nil, class: 'icon-off clgray'
    end
  end

  def public_icon
    content_tag :i, nil, class: 'icon-globe cblue'
  end

  def private_icon
    content_tag :i, nil, class: 'icon-lock cgreen'
  end
end
