# frozen_string_literal: true

module DevOpsReportHelper
  def devops_score_metrics(metric)
    return {} if metric.blank?

    {
      averageScore: average_score_data(metric),
      cards: devops_score_card_data(metric),
      createdAt: metric.created_at.strftime('%Y-%m-%d %H:%M')
    }
  end

  private

  def format_score(score)
    precision = score < 1 ? 2 : 1
    number_with_precision(score, precision: precision)
  end

  def score_level(score)
    if score < 33.33
      {
        label: s_('DevopsReport|Low'),
        variant: 'muted'
      }
    elsif score < 66.66
      {
        label: s_('DevopsReport|Moderate'),
        variant: 'neutral'
      }
    else
      {
        label: s_('DevopsReport|High'),
        variant: 'success'
      }
    end
  end

  def average_score_level(score)
    if score < 33.33
      {
        label: s_('DevopsReport|Low'),
        variant: 'danger',
        icon: 'status-failed'
      }
    elsif score < 66.66
      {
        label: s_('DevopsReport|Moderate'),
        variant: 'warning',
        icon: 'status-alert'
      }
    else
      {
        label: s_('DevopsReport|High'),
        variant: 'success',
        icon: 'status_success_solid'
      }
    end
  end

  def average_score_data(metric)
    {
      value: format_score(metric.average_percentage_score),
      scoreLevel: average_score_level(metric.average_percentage_score)
    }
  end

  def devops_score_card_data(metric)
    metric.cards.map do |card|
      {
        title: "#{card.title} #{card.description}",
        usage: format_score(card.instance_score),
        leadInstance: format_score(card.leader_score),
        score: format_score(card.percentage_score),
        scoreLevel: score_level(card.percentage_score)
      }
    end
  end
end
