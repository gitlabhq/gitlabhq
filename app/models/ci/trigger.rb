module Ci
  class Trigger < ActiveRecord::Base
    extend Ci::Model

    acts_as_paranoid

    belongs_to :project
    belongs_to :owner, class_name: "User"

    has_many :trigger_requests
    has_one :trigger_schedule, dependent: :destroy

    validates :token, presence: true, uniqueness: true

    before_validation :set_default_values

    accepts_nested_attributes_for :trigger_schedule

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?
    end

    def last_trigger_request
      trigger_requests.last
    end

    def last_used
      last_trigger_request.try(:created_at)
    end

    def short_token
      token[0...4]
    end

    def legacy?
      self.owner_id.blank?
    end

    def can_access_project?
      self.owner_id.blank? || Ability.allowed?(self.owner, :create_build, project)
    end

    def trigger_schedule
      super || build_trigger_schedule(project: project)
    end
  end
end
