# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Reader
      attr_reader :tree, :attributes_finder

      def initialize(shared:)
        @shared = shared

        @attributes_finder = Gitlab::ImportExport::AttributesFinder.new(
          config: ImportExport::Config.new.to_h)
      end

      # Outputs a hash in the format described here: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
      # for outputting a project in JSON format, including its relations and sub relations.
      def project_tree
        attributes_finder.find_root(:project)
      rescue => e
        @shared.error(e)
        false
      end

      def group_members_tree
        attributes_finder.find_root(:group_members)
      end
    end
  end
end
