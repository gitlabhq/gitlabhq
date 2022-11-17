# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildPrimaryXmlService < BuildXmlBaseService
        ROOT_TAG = 'metadata'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/common',
          'xmlns:rpm': 'http://linux.duke.edu/metadata/rpm',
          packages: '0'
        }.freeze

        # Nodes that have only text without attributes
        BASE_ATTRIBUTES = %i[name arch summary description url packager].freeze
        FORMAT_NODE_BASE_ATTRIBUTES = %i[license vendor group buildhost sourcerpm].freeze

        def execute
          super do |xml|
            xml.package(type: :rpm, 'xmlns:rpm': 'http://linux.duke.edu/metadata/rpm') do
              build_base_attributes(xml)
              xml.version epoch: data[:epoch], ver: data[:version], rel: data[:release]
              xml.checksum data[:pkgid], type: 'sha256', pkgid: 'YES'
              xml.size package: data[:packagesize], installed: data[:installedsize], archive: data[:archivesize]
              xml.time file: data[:filetime], build: data[:buildtime]
              xml.location href: data[:location] if data[:location].present?
              build_format_node(xml)
            end
          end
        end

        private

        def build_base_attributes(xml)
          BASE_ATTRIBUTES.each do |attribute|
            xml.method_missing(attribute, data[attribute]) if data[attribute].present?
          end
        end

        def build_format_node(xml)
          xml.format do
            build_base_format_attributes(xml)
            build_provides_node(xml)
            build_requires_node(xml)
          end
        end

        def build_base_format_attributes(xml)
          FORMAT_NODE_BASE_ATTRIBUTES.each do |attribute|
            xml[:rpm].method_missing(attribute, data[attribute]) if data[attribute].present?
          end
        end

        def build_requires_node(xml)
          xml[:rpm].requires do
            data[:requirements].each do |requires|
              xml[:rpm].entry(
                name: requires[:requirename],
                flags: requires[:requireflags],
                ver: requires[:requireversion]
              )
            end
          end
        end

        def build_provides_node(xml)
          xml[:rpm].provides do
            data[:provides].each do |provides|
              xml[:rpm].entry(
                name: provides[:providename],
                flags: provides[:provideflags],
                ver: provides[:provideversion])
            end
          end
        end
      end
    end
  end
end
