module Ci
  class Trigger < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include IgnorableColumn

    ignore_column :deleted_at

    belongs_to :project
    belongs_to :owner, class_name: "User"

    has_many :trigger_requests

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

    def legacy?
      self.owner_id.blank?
    end

    def can_access_project?
      self.owner_id.blank? || Ability.allowed?(self.owner, :create_build, project)
    end
  end
end
