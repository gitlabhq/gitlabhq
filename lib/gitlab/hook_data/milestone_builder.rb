# frozen_string_literal: true

module Gitlab
  module HookData
    class MilestoneBuilder < BaseBuilder
      SAFE_HOOK_ATTRIBUTES = %i[
        id
        iid
        title
        description
        state
        created_at
        updated_at
        due_date
        start_date
        project_id
      ].freeze

      alias_method :milestone, :object

      def build
        milestone
          .attributes
          .with_indifferent_access
          .slice(*SAFE_HOOK_ATTRIBUTES)
      end
    end
  end
end
