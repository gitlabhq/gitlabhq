# frozen_string_literal: true

class CohortEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper

  expose :registration_month do |cohort|
    cohort[:registration_month].strftime('%b %Y')
  end

  expose :total do |cohort|
    number_with_delimiter(cohort[:total])
  end

  expose :inactive do |cohort|
    number_with_delimiter(cohort[:inactive])
  end

  expose :activity_months, using: CohortActivityMonthEntity
end
