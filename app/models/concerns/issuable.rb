# == Issuable concern
#
# Contains common functionality shared between Issues and MergeRequests
#
# Used by Issue, MergeRequest
#
module Issuable
  extend ActiveSupport::Concern
  include Participable
  include Mentionable

  included do
    belongs_to :author, class_name: "User"
    belongs_to :assignee, class_name: "User"
    belongs_to :updated_by, class_name: "User"
    belongs_to :milestone
    has_many :notes, as: :noteable, dependent: :destroy
    has_many :label_links, as: :target, dependent: :destroy
    has_many :labels, through: :label_links
    has_many :subscriptions, dependent: :destroy, as: :subscribable

    validates :author, presence: true
    validates :title, presence: true, length: { within: 0..255 }

    scope :authored, ->(user) { where(author_id: user) }
    scope :assigned_to, ->(u) { where(assignee_id: u.id)}
    scope :recent, -> { reorder(id: :desc) }
    scope :assigned, -> { where("assignee_id IS NOT NULL") }
    scope :unassigned, -> { where("assignee_id IS NULL") }
    scope :of_projects, ->(ids) { where(project_id: ids) }
    scope :opened, -> { with_state(:opened, :reopened) }
    scope :only_opened, -> { with_state(:opened) }
    scope :only_reopened, -> { with_state(:reopened) }
    scope :closed, -> { with_state(:closed) }
    scope :order_milestone_due_desc, -> { joins(:milestone).reorder('milestones.due_date DESC, milestones.id DESC') }
    scope :order_milestone_due_asc, -> { joins(:milestone).reorder('milestones.due_date ASC, milestones.id ASC') }

    delegate :name,
             :email,
             to: :author,
             prefix: true

    delegate :name,
             :email,
             to: :assignee,
             allow_nil: true,
             prefix: true

    attr_mentionable :title, :description
    participant :author, :assignee, :notes_with_associations
  end

  module ClassMethods
    def search(query)
      where("LOWER(title) like :query", query: "%#{query.downcase}%")
    end

    def full_search(query)
      where("LOWER(title) like :query OR LOWER(description) like :query", query: "%#{query.downcase}%")
    end

    def sort(method)
      case method.to_s
      when 'milestone_due_asc' then order_milestone_due_asc
      when 'milestone_due_desc' then order_milestone_due_desc
      else
        order_by(method)
      end
    end
  end

  def today?
    Date.today == created_at.to_date
  end

  def new?
    today? && created_at == updated_at
  end

  def is_assigned?
    !!assignee_id
  end

  def is_being_reassigned?
    assignee_id_changed?
  end

  def open?
    opened? || reopened?
  end

  # Deprecated. Still exists to preserve API compatibility.
  def downvotes
    0
  end

  # Deprecated. Still exists to preserve API compatibility.
  def upvotes
    0
  end

  def subscribed?(user)
    subscription = subscriptions.find_by_user_id(user.id)

    if subscription
      return subscription.subscribed
    end

    participants(user).include?(user)
  end

  def toggle_subscription(user)
    subscriptions.
      find_or_initialize_by(user_id: user.id).
      update(subscribed: !subscribed?(user))
  end

  def to_hook_data(user)
    {
      object_kind: self.class.name.underscore,
      user: user.hook_attrs,
      repository: {
          name: project.name,
          url: project.url_to_repo,
          description: project.description,
          homepage: project.web_url
      },
      object_attributes: hook_attrs
    }
  end

  def label_names
    labels.order('title ASC').pluck(:title)
  end

  def remove_labels
    labels.delete_all
  end

  def add_labels_by_names(label_names)
    label_names.each do |label_name|
      label = project.labels.create_with(color: Label::DEFAULT_COLOR).
        find_or_create_by(title: label_name.strip)
      self.labels << label
    end
  end

  # Convert this Issuable class name to a format usable by Ability definitions
  #
  # Examples:
  #
  #   issuable.class           # => MergeRequest
  #   issuable.to_ability_name # => "merge_request"
  def to_ability_name
    self.class.to_s.underscore
  end

  def notes_with_associations
    notes.includes(:author, :project)
  end
end
