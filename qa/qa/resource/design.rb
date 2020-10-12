# frozen_string_literal: true

module QA
  module Resource
    class Design < Base
      attr_reader :id
      attr_accessor :filename

      attribute :issue do
        Issue.fabricate_via_api!
      end

      def initialize
        @update = false
        @filename = 'banana_sample.gif'
      end

      # TODO This will be replaced as soon as file uploads over GraphQL are implemented
      def fabricate!
        issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.add_design(filepath)
        end
      end

      private

      def filepath
        ::File.absolute_path(::File.join('qa', 'fixtures', 'designs', @filename))
      end
    end
  end
end
