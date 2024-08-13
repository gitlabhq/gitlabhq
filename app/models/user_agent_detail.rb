# frozen_string_literal: true

class UserAgentDetail < ApplicationRecord
  belongs_to :subject, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :user_agent, :ip_address, :subject_id, :subject_type, presence: true

  def submittable?
    !submitted?
  end
end
