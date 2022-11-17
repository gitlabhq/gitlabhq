# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildFilelistXmlService < BuildXmlBaseService
        ROOT_TAG = 'filelists'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/filelists',
          packages: '0'
        }.freeze

        def execute
          super do |xml|
            xml.package(pkgid: data[:pkgid], name: data[:name], arch: data[:arch]) do
              xml.version epoch: data[:epoch], ver: data[:version], rel: data[:release]
              build_file_nodes(xml)
            end
          end
        end

        private

        def build_file_nodes(xml)
          data[:files].each do |path|
            attributes = dir?(path) ? { type: 'dir' } : {}

            xml.file path, **attributes
          end
        end

        def dir?(path)
          # Add trailing slash to path to check
          # if it exists in directories list
          data[:directories].include? File.join(path, '')
        end
      end
    end
  end
end
