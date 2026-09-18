# frozen_string_literal: true

module Search
  module AdvancedFinders
    class GroupsFinder
      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params
      end

      # Overwritten in ee/lib/ee/search/advanced_finders/groups_finder.rb
      def use_elasticsearch_finder?
        false
      end
    end
  end
end

Search::AdvancedFinders::GroupsFinder.prepend_mod
