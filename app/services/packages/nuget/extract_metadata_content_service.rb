# frozen_string_literal: true

module Packages
  module Nuget
    class ExtractMetadataContentService
      ROOT_XPATH = '//xmlns:package/xmlns:metadata/xmlns'

      XPATHS = {
        package_name: "#{ROOT_XPATH}:id",
        package_version: "#{ROOT_XPATH}:version",
        authors: "#{ROOT_XPATH}:authors",
        description: "#{ROOT_XPATH}:description",
        license_url: "#{ROOT_XPATH}:licenseUrl",
        project_url: "#{ROOT_XPATH}:projectUrl",
        icon_url: "#{ROOT_XPATH}:iconUrl"
      }.freeze

      XPATH_DEPENDENCIES = "#{ROOT_XPATH}:dependencies/xmlns:dependency".freeze
      XPATH_DEPENDENCY_GROUPS = "#{ROOT_XPATH}:dependencies/xmlns:group".freeze
      XPATH_TAGS = "#{ROOT_XPATH}:tags".freeze
      XPATH_PACKAGE_TYPES = "#{ROOT_XPATH}:packageTypes/xmlns:packageType".freeze

      def initialize(nuspec_file_content)
        @nuspec_file_content = nuspec_file_content
      end

      def execute
        ServiceResponse.success(payload: extract_metadata(nuspec_file_content))
      end

      private

      attr_reader :nuspec_file_content

      def extract_metadata(file)
        doc = Nokogiri::XML(file)

        XPATHS.transform_values { |query| doc.xpath(query).text.presence }
              .compact
              .tap do |metadata|
                metadata[:package_dependencies] = extract_dependencies(doc)
                metadata[:package_tags] = extract_tags(doc)
                metadata[:package_types] = extract_package_types(doc)
              end
      end

      def extract_dependencies(doc)
        dependencies = []

        doc.xpath(XPATH_DEPENDENCIES).each do |node|
          dependencies << extract_dependency(node)
        end

        doc.xpath(XPATH_DEPENDENCY_GROUPS).each do |group_node|
          target_framework = group_node.attr('targetFramework')

          group_node.xpath('xmlns:dependency').each do |node|
            dependencies << extract_dependency(node).merge(target_framework: target_framework)
          end
        end

        dependencies
      end

      def extract_dependency(node)
        {
          name: node.attr('id'),
          version: node.attr('version')
        }.compact
      end

      def extract_tags(doc)
        tags = doc.xpath(XPATH_TAGS).text

        return [] if tags.blank?

        tags.split(::Packages::Tag::NUGET_TAGS_SEPARATOR)
      end

      def extract_package_types(doc)
        doc.xpath(XPATH_PACKAGE_TYPES).map { |node| node.attr('name') }.uniq
      end
    end
  end
end
