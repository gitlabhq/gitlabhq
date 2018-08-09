# frozen_string_literal: true

class CohortActivityMonthEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper

  expose :total do |cohort_activity_month|
    number_with_delimiter(cohort_activity_month[:total])
  end

  expose :percentage do |cohort_activity_month|
    number_to_percentage(cohort_activity_month[:percentage], precision: 0)
  end
end
