# frozen_string_literal: true

module DevOpsScoreHelper
  def score_level(score)
    if score < 33.33
      'low'
    elsif score < 66.66
      'average'
    else
      'high'
    end
  end

  def format_score(score)
    precision = score < 1 ? 2 : 1
    number_with_precision(score, precision: precision)
  end
end
