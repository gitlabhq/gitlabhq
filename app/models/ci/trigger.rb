module Ci
  class Trigger < ActiveRecord::Base
    extend Ci::Model

    acts_as_paranoid

    belongs_to :project, foreign_key: :gl_project_id
    belongs_to :owner, class_name: "User"

    has_many :trigger_requests, dependent: :destroy

    validates :token, presence: true, uniqueness: true

    before_validation :set_default_values

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

    def can_show_token?(user)
      owner.blank? || owner == user
    end
  end
end
