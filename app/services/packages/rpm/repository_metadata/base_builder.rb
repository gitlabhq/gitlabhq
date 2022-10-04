# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BaseBuilder
        def initialize(xml: nil, data: {})
          @xml = Nokogiri::XML(xml) if xml.present?
          @data = data
        end

        def execute
          return build_empty_structure if xml.blank?

          update_xml_document
          update_package_count
          xml.to_xml
        end

        private

        attr_reader :xml, :data

        def build_empty_structure
          Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.method_missing(self.class::ROOT_TAG, self.class::ROOT_ATTRIBUTES)
          end.to_xml
        end

        def update_xml_document
          # Add to the root xml element a new package metadata node
          xml.at(self.class::ROOT_TAG).add_child(build_new_node)
        end

        def update_package_count
          packages_count = xml.css("//#{self.class::ROOT_TAG}/package").count

          xml.at(self.class::ROOT_TAG).attributes["packages"].value = packages_count.to_s
        end

        def build_new_node
          raise NotImplementedError, "#{self.class} should implement #{__method__}"
        end
      end
    end
  end
end
