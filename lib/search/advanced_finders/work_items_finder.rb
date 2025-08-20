# frozen_string_literal: true

module Search
  module AdvancedFinders
    class WorkItemsFinder
      def initialize(current_user, context, resource_parent, params = {})
        @current_user = current_user
        @context = context
        @resource_parent = resource_parent
        @params = params
      end

      # Overwritten in ee/lib/ee/search/advanced_finders/work_items_finder.rb
      def use_elasticsearch_finder?
        false
      end
    end
  end
end

Search::AdvancedFinders::WorkItemsFinder.prepend_mod
