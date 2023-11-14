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

        def initialize(name = self.class.name, version = nil, _type = nil)
          raise MilestoneNotSetError, "Milestone is not set for #{name}" if milestone.nil?

          super(name, version)
        end

        def milestone # rubocop:disable Lint/DuplicateMethods
          @milestone ||= self.class.milestone
        end
      end
    end
  end
end
