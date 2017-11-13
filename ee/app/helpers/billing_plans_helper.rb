module BillingPlansHelper
  def subscription_plan_info(plans_data, current_plan_code)
    plans_data.find { |plan| plan.code == current_plan_code }
  end

  def number_to_plan_currency(value)
    number_to_currency(value, unit: '$', strip_insignificant_zeros: true, format: "%u%n")
  end

  def current_plan?(plan)
    plan.purchase_link&.action == 'current_plan'
  end

  def has_plan_purchase_link?(plans_data)
    plans_data.any? { |plan| plan.purchase_link&.href }
  end

  def plan_purchase_link(href, link_text)
    if href
      link_to link_text, href, class: 'btn btn-primary btn-inverted'
    else
      button_tag link_text, class: 'btn disabled'
    end
  end
end
