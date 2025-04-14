# frozen_string_literal: true

module WorkItems
  module Glql
    class WorkItemsFinder
      def initialize(current_user, context, resource_parent, params = {})
        @current_user = current_user
        @context = context
        @resource_parent = resource_parent
        @params = params
      end

      # Overwritten in ee/app/finders/ee/work_items/glql/work_items_finder.rb
      def use_elasticsearch_finder?
        false
      end
    end
  end
end

WorkItems::Glql::WorkItemsFinder.prepend_mod
