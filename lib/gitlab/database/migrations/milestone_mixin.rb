# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module MilestoneMixin
        extend ActiveSupport::Concern
        include Gitlab::ClassAttributes

        MilestoneNotSetError = Class.new(StandardError)

        class_methods do
          def milestone(milestone_str = nil)
            if milestone_str.present?
              set_class_attribute(:migration_milestone, milestone_str)
            else
              get_class_attribute(:migration_milestone)
            end
          end
        end

        def type_from_path(path)
          dir = File.dirname(path)
          return :post if dir.match?(%r{db/(\w+/)?post_migrate})
          return :regular if dir.match?(%r{db/(\w+/)?migrate})

          raise 'unknown migration path'
        end

        def initialize(name = self.class.name, version = nil)
          raise MilestoneNotSetError, "Milestone is not set for #{name}" if milestone.nil?

          super(name, version)
          @version = Gitlab::Database::Migrations::Version.new(
            version,
            milestone,
            type_from_path(self.class.instance_variable_get(:@_defining_file))
          )
        end

        def milestone
          @milestone ||= self.class.milestone
        end
      end
    end
  end
end
