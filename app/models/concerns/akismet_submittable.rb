module AkismetSubmittable
  extend ActiveSupport::Concern

  included do
    has_one :user_agent_detail, as: :subject
  end

  def can_be_submitted?
    if user_agent_detail
      user_agent_detail.submittable?
    else
      false
    end
  end
end
