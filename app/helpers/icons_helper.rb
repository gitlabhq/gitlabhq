module IconsHelper
  def boolean_to_icon(value)
    if value.to_s == "true"
      content_tag :i, nil, class: 'icon-circle cgreen'
    else
      content_tag :i, nil, class: 'icon-off clgray'
    end
  end

  def public_icon
    content_tag :i, nil, class: 'icon-globe'
  end

  def internal_icon
    content_tag :i, nil, class: 'icon-shield'
  end

  def private_icon
    content_tag :i, nil, class: 'icon-lock'
  end
end
