# Contains common functionality shared between Issues and MergeRequests
module IssueCommonality
  extend ActiveSupport::Concern

  included do
    belongs_to :project
    belongs_to :author, class_name: "User"
    belongs_to :assignee, class_name: "User"
    has_many :notes, as: :noteable, dependent: :destroy

    validates_presence_of :project_id
    validates_presence_of :author_id

    validates :title,
              presence: true,
              length: { within: 0..255 }
    validates :closed, inclusion: { in: [true, false] }

    scope :opened, where(closed: false)
    scope :closed, where(closed: true)
    scope :assigned, lambda { |u| where(assignee_id: u.id)}

    delegate :name,
             :email,
             to: :author,
             prefix: true

    delegate :name,
             :email,
             to: :assignee,
             allow_nil: true,
             prefix: true

    attr_accessor :author_id_of_changes
  end

  module ClassMethods
    def search(query)
      where("title like :query", query: "%#{query}%")
    end
  end

  def today?
    Date.today == created_at.to_date
  end

  def new?
    today? && created_at == updated_at
  end
end
