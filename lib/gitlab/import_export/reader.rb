# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Reader
      attr_reader :tree, :attributes_finder

      def initialize(shared:, config: ImportExport::Config.new.to_h)
        @shared            = shared
        @config            = config
        @attributes_finder = Gitlab::ImportExport::AttributesFinder.new(config: @config)
      end

      # Outputs a hash in the format described here: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
      # for outputting a project in JSON format, including its relations and sub relations.
      def project_tree
        tree_by_key(:project)
      end

      def project_relation_names
        attributes_finder.find_relations_tree(:project).keys
      end

      def group_tree
        tree_by_key(:group)
      end

      def group_relation_names
        attributes_finder.find_relations_tree(:group).keys
      end

      def group_members_tree
        tree_by_key(:group_members)
      end

      def tree_by_key(key)
        attributes_finder.find_root(key)
      rescue StandardError => e
        @shared.error(e)
        false
      end
    end
  end
end
