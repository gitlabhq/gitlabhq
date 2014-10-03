module IconsHelper
  def boolean_to_icon(value)
    if value.to_s == "true"
      content_tag :i, nil, class: 'fa fa-circle cgreen'
    else
      content_tag :i, nil, class: 'fa fa-power-off clgray'
    end
  end

  def public_icon
    content_tag :i, nil, class: 'fa fa-globe'
  end

  def internal_icon
    content_tag :i, nil, class: 'fa fa-shield'
  end

  def private_icon
    content_tag :i, nil, class: 'fa fa-lock'
  end
end
