class UserAgentDetail < ActiveRecord::Base
  belongs_to :subject, polymorphic: true

  validates :user_agent,
            presence: true
  validates :ip_address,
            presence: true
  validates :subject_id,
            presence: true
  validates :subject_type,
            presence: true

  def submittable?
    user_agent.present? && ip_address.present?
  end
end
