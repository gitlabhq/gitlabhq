module ConvdevHelper
  def metric_score_class(card, metric)
    case metric["#{card[:id]}_level"]
    when 'low'
      'convdev-card-low'
    when 'average'
      'convdev-card-med'
    when 'high'
      'convdev-card-high'
    end
  end
end
