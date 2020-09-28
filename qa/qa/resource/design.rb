# frozen_string_literal: true

module QA
  module Resource
    class Design < Base
      attribute :issue do
        Issue.fabricate_via_api!
      end

      attribute :filepath do
        ::File.absolute_path(::File.join('spec', 'fixtures', @filename))
      end

      attribute :id
      attribute :filename

      def initialize
        @filename = 'banana_sample.gif'
      end

      # TODO This will be replaced as soon as file uploads over GraphQL are implemented
      def fabricate!
        issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.add_design(filepath)
        end
      end
    end
  end
end
