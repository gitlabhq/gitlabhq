# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class UpdateXmlService
        BUILDERS = {
          other: ::Packages::Rpm::RepositoryMetadata::BuildOtherXmlService,
          primary: ::Packages::Rpm::RepositoryMetadata::BuildPrimaryXmlService,
          filelist: ::Packages::Rpm::RepositoryMetadata::BuildFilelistXmlService
        }.freeze

        def initialize(filename:, xml: nil, data: {})
          @builder_class = BUILDERS[filename]
          raise ArgumentError, "Filename must be one of: #{BUILDERS.keys.join(', ')}" if @builder_class.nil?

          @xml = Nokogiri::XML(xml) if xml.present?
          @data = data
          @filename = filename
        end

        def execute
          return build_empty_structure if xml.blank?

          remove_existing_packages
          update_xml_document
          update_package_count
          xml.to_xml
        end

        private

        attr_reader :xml, :data, :builder_class, :filename

        def build_empty_structure
          Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.method_missing(builder_class::ROOT_TAG, builder_class::ROOT_ATTRIBUTES)
          end.to_xml
        end

        def update_xml_document
          # Add to the root xml element a new package metadata node
          xml.at(builder_class::ROOT_TAG).add_child(builder_class.new(data).execute)
        end

        def update_package_count
          packages_count = xml.css("//#{builder_class::ROOT_TAG}/package").count

          xml.at(builder_class::ROOT_TAG).attributes["packages"].value = packages_count.to_s
        end

        def remove_existing_packages
          case filename
          when :primary
            xml.search("checksum:contains('#{data[:pkgid]}')").each { _1.parent&.remove }
          else
            xml.search("[pkgid='#{data[:pkgid]}']").each(&:remove)
          end
        end
      end
    end
  end
end
