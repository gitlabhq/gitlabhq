# frozen_string_literal: true
module Packages
  module Npm
    class CreateTagService
      include Gitlab::Utils::StrongMemoize

      attr_reader :package, :tag_name

      def initialize(package, tag_name)
        @package = package
        @tag_name = tag_name
      end

      def execute
        if existing_tag.present?
          existing_tag.update_column(:package_id, package.id)
          existing_tag
        else
          package.tags.create!(name: tag_name)
        end
      end

      private

      def existing_tag
        strong_memoize(:existing_tag) do
          Packages::TagsFinder
            .new(package.project, package.name, package_type: package.package_type)
            .find_by_name(tag_name)
        end
      end
    end
  end
end
