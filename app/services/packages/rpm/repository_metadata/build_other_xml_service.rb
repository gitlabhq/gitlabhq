# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildOtherXmlService < BuildXmlBaseService
        ROOT_TAG = 'otherdata'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/other',
          packages: '0'
        }.freeze

        def execute
          super do |xml|
            xml.package(pkgid: data[:pkgid], name: data[:name], arch: data[:arch]) do
              xml.version epoch: data[:epoch], ver: data[:version], rel: data[:release]
              build_changelog_nodes(xml)
            end
          end
        end

        private

        def build_changelog_nodes(xml)
          data[:changelogs].each do |changelog|
            xml.changelog changelog[:changelogtext], date: changelog[:changelogtime]
          end
        end
      end
    end
  end
end
