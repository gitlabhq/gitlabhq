# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildRepomdXmlService
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/repo',
          'xmlns:rpm': 'http://linux.duke.edu/metadata/rpm'
        }.freeze
        ALLOWED_DATA_VALUE_KEYS = %i[checksum open-checksum location timestamp size open-size].freeze

        # Expected `data` structure
        #
        # data = {
        #   filelists: {
        #     checksum: { type: "sha256", value: "123" },
        #     location: { href: "repodata/123-filelists.xml.gz" },
        #     ...
        #   },
        #   ...
        # }
        def initialize(data)
          @data = data
        end

        def execute
          Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.repomd(ROOT_ATTRIBUTES) do
              xml.revision Time.now.to_i
              build_data_info(xml)
            end
          end.to_xml
        end

        private

        attr_reader :data

        def build_data_info(xml)
          data.each do |filename, info|
            xml.data(type: filename) do
              build_file_info(info, xml)
            end
          end
        end

        def build_file_info(info, xml)
          info.slice(*ALLOWED_DATA_VALUE_KEYS).each do |key, attributes|
            value = attributes.delete(:value)
            xml.method_missing(key, value, attributes)
          end
        end
      end
    end
  end
end
