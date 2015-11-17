# == Schema Information
#
# Table name: ci_services
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
module Ci
  class Service < ActiveRecord::Base
    extend Ci::Model
    
    serialize :properties, JSON

    default_value_for :active, false

    after_initialize :initialize_properties

    belongs_to :project, class_name: 'Ci::Project'

    validates :project_id, presence: true

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

    def can_test?
      project.builds.any?
    end

    def can_execute?(build)
      true
    end

    def execute(build)
      # implement inside child
    end

    # Provide convenient accessor methods
    # for each serialized property.
    def self.prop_accessor(*args)
      args.each do |arg|
        class_eval %{
          def #{arg}
            (properties || {})['#{arg}']
          end

          def #{arg}=(value)
            self.properties ||= {}
            self.properties['#{arg}'] = value
          end
        }
      end
    end

    def self.boolean_accessor(*args)
      self.prop_accessor(*args)

      args.each do |arg|
        class_eval %{
          def #{arg}?
            ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(#{arg})
          end
        }
      end
    end
  end
end
