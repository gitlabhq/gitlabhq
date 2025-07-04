# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Milestone
      extend self

      SAMPLE_DATA = {
        id: 1,
        iid: 1,
        title: 'Sample milestone',
        description: 'Sample milestone description',
        state: 'active',
        created_at: Time.current,
        updated_at: Time.current,
        due_date: 1.week.from_now,
        start_date: Time.current
      }.freeze

      def build(milestone, action)
        {
          object_kind: 'milestone',
          event_type: 'milestone',
          project: milestone.project&.hook_attrs,
          object_attributes: milestone.hook_attrs,
          action: action
        }
      end

      def build_sample(project)
        milestone = project.milestones.first || ::Milestone.new(SAMPLE_DATA.merge(project: project))
        build(milestone, 'create')
      end
    end
  end
end
