# frozen_string_literal: true

module Gitlab
  module HookData
    class MilestoneBuilder < BaseBuilder
      def self.safe_hook_attributes
        %i[
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
      end

      alias_method :milestone, :object

      def build
        milestone
          .attributes
          .with_indifferent_access
          .slice(*self.class.safe_hook_attributes)
      end
    end
  end
end

Gitlab::HookData::MilestoneBuilder.prepend_mod
