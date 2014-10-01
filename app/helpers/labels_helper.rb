module LabelsHelper
  def project_label_names
    @project.labels.pluck(:title)
  end

  def label_color(label)
    label.color || Label::DEFAULT_COLOR
  end

  def text_color(label_color)
    text_color_for_bg(label_color)
  end

  def suggested_colors
    [
      '#D9534F',
      '#F0AD4E',
      '#428BCA',
      '#5CB85C',
      '#34495E',
      '#7F8C8D',
      '#8E44AD',
      '#FFECDB'
    ]
  end

  def text_color_for_bg(bg_color)
    r, g, b = bg_color.slice(1,7).scan(/.{2}/).map(&:hex)

    if (r + g + b) > 500
      "#333"
    else
      "#FFF"
    end
  end
end
