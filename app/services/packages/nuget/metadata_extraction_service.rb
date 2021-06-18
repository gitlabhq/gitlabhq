# frozen_string_literal: true

module Packages
  module Nuget
    class MetadataExtractionService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      XPATHS = {
        package_name: '//xmlns:package/xmlns:metadata/xmlns:id',
        package_version: '//xmlns:package/xmlns:metadata/xmlns:version',
        license_url: '//xmlns:package/xmlns:metadata/xmlns:licenseUrl',
        project_url: '//xmlns:package/xmlns:metadata/xmlns:projectUrl',
        icon_url: '//xmlns:package/xmlns:metadata/xmlns:iconUrl'
      }.freeze

      XPATH_DEPENDENCIES = '//xmlns:package/xmlns:metadata/xmlns:dependencies/xmlns:dependency'
      XPATH_DEPENDENCY_GROUPS = '//xmlns:package/xmlns:metadata/xmlns:dependencies/xmlns:group'
      XPATH_TAGS = '//xmlns:package/xmlns:metadata/xmlns:tags'
      XPATH_PACKAGE_TYPES = '//xmlns:package/xmlns:metadata/xmlns:packageTypes/xmlns:packageType'

      MAX_FILE_SIZE = 4.megabytes.freeze

      def initialize(package_file_id)
        @package_file_id = package_file_id
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        extract_metadata(nuspec_file_content)
      end

      private

      def package_file
        strong_memoize(:package_file) do
          ::Packages::PackageFile.find_by_id(@package_file_id)
        end
      end

      def project
        package_file.package.project
      end

      def valid_package_file?
        package_file &&
          package_file.package&.nuget? &&
          package_file.file.size > 0 # rubocop:disable Style/ZeroLengthPredicate
      end

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
          target_framework = group_node.attr("targetFramework")

          group_node.xpath("xmlns:dependency").each do |node|
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

      def extract_package_types(doc)
        doc.xpath(XPATH_PACKAGE_TYPES).map { |node| node.attr('name') }.uniq
      end

      def extract_tags(doc)
        tags = doc.xpath(XPATH_TAGS).text

        return [] if tags.blank?

        tags.split(::Packages::Tag::NUGET_TAGS_SEPARATOR)
      end

      def nuspec_file_content
        with_zip_file do |zip_file|
          entry = zip_file.glob('*.nuspec').first

          raise ExtractionError, 'nuspec file not found' unless entry
          raise ExtractionError, 'nuspec file too big' if entry.size > MAX_FILE_SIZE

          entry.get_input_stream.read
        end
      end

      def with_zip_file(&block)
        package_file.file.use_open_file do |open_file|
          zip_file = Zip::File.new(open_file, false, true)
          yield(zip_file)
        end
      end
    end
  end
end
