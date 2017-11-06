module EE
  module Epic
    extend ActiveSupport::Concern

    prepended do
      include InternalId
      include Issuable
      include Noteable

      belongs_to :assignee, class_name: "User"
      belongs_to :group

      validates :group, presence: true
    end

    def assignees
      Array(assignee)
    end

    def project
      nil
    end

    def supports_weight?
      false
    end
  end
end
