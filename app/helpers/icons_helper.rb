module IconsHelper
  # Creates an icon tag given icon name(s) and possible icon modifiers.
  #
  # Right now this method simply delegates directly to `fa_icon` from the
  # font-awesome-rails gem, but should we ever use a different icon pack in the
  # future we won't have to change hundreds of method calls.
  def icon(names, options = {})
    fa_icon(names, options)
  end

  def spinner(text = nil, visible = false)
    css_class = 'loading'
    css_class << ' hide' unless visible

    content_tag :div, class: css_class do
      icon('spinner spin') + text
    end
  end

  def boolean_to_icon(value)
    if value.to_s == "true"
      icon('circle', class: 'cgreen')
    else
      icon('power-off', class: 'clgray')
    end
  end

  def public_icon
    icon('globe')
  end

  def internal_icon
    icon('shield')
  end

  def private_icon
    icon('lock')
  end
end
