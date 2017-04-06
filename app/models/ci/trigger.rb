module Ci
  class Trigger < ActiveRecord::Base
    extend Ci::Model

    acts_as_paranoid

    belongs_to :project
    belongs_to :owner, class_name: "User"

    has_many :trigger_requests, dependent: :destroy
    has_one :trigger_schedule, dependent: :destroy

    validates :token, presence: true, uniqueness: true

    before_validation :set_default_values

    accepts_nested_attributes_for :trigger_schedule

    attr_accessor :trigger_schedule_on

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?

      if trigger_schedule_on.present?
        if trigger_schedule_on.to_i == 1
          self.trigger_schedule.project = project
          self.trigger_schedule.trigger = self
        else
          self.trigger_schedule = nil
        end
      end
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
  end
end
