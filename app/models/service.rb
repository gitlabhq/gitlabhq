# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

# To add new service you should build a class inherited from Service
# and implement a set of methods
class Service < ActiveRecord::Base
  include Sortable
  serialize :properties, JSON

  default_value_for :active, false

  after_initialize :initialize_properties

  belongs_to :project
  has_one :service_hook

  validates :project_id, presence: true

  scope :visible, -> { where.not(type: 'GitlabIssueTrackerService') }

  def activated?
    active
  end

  def category
    :common
  end

  def initialize_properties
    self.properties = {} if properties.nil?
  end

  def title
    # implement inside child
  end

  def description
    # implement inside child
  end

  def help
    # implement inside child
  end

  def to_param
    # implement inside child
  end

  def fields
    # implement inside child
    []
  end

  def execute
    # implement inside child
  end

  def can_test?
    !project.empty_repo?
  end

  # Provide a way to track property changes
  def update_attributes(attributes)
    @changed_properties = properties.dup
    super
  end

  def changed_properties
    @changed_properties ||= ActiveSupport::HashWithIndifferentAccess.new
  end

  # Provide convenient accessor methods
  # for each serialized property.
  def self.prop_accessor(*args)
    args.each do |arg|
      class_eval %{
        def #{arg}
          properties['#{arg}']
        end

        def #{arg}=(value)
          self.properties['#{arg}'] = value
        end

        def #{arg}_was
          #{arg}_changed? ? changed_properties['#{arg}'] : properties['#{arg}']
        end

        def #{arg}_changed?
          changed_properties.present? && changed_properties['#{arg}'] != properties['#{arg}']
        end
      }
    end
  end

  def async_execute(data)
    Sidekiq::Client.enqueue(ProjectServiceWorker, id, data)
  end

  def issue_tracker?
    self.category == :issue_tracker
  end

  def self.issue_tracker_service_list
    Service.select(&:issue_tracker?).map{ |s| s.to_param }
  end
end
