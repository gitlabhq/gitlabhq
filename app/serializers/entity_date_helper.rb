module EntityDateHelper
  include ActionView::Helpers::DateHelper

  def interval_in_words(diff)
    "#{distance_of_time_in_words(diff.to_f)} ago"
  end
end
