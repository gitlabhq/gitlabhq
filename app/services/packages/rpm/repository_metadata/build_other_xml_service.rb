# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildOtherXmlService
        ROOT_TAG = 'otherdata'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/other',
          packages: '0'
        }.freeze

        def initialize(data)
          @data = data
        end

        def execute
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.package(pkgid: data[:pkgid], name: data[:name], arch: data[:arch]) do
              xml.version epoch: data[:epoch], ver: data[:version], rel: data[:release]
              build_changelog_nodes(xml)
            end
          end

          Nokogiri::XML(builder.to_xml).at('package')
        end

        private

        attr_reader :data

        def build_changelog_nodes(xml)
          data[:changelogs].each do |changelog|
            xml.changelog changelog[:changelogtext], date: changelog[:changelogtime]
          end
        end
      end
    end
  end
end
