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
        Packages::TagsFinder
            .new(package.project, package.name, tags_finder_options)
            .find_by_name(tag_name)
      end
      strong_memoize_attr :existing_tag

      def tags_finder_options
        if Feature.enabled?(:packages_tags_finder_use_packages_class, package.project)
          { packages_class: ::Packages::Npm::Package }
        else
          { package_type: package.package_type }
        end
      end
    end
  end
end
