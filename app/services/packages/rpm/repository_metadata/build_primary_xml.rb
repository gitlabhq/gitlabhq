# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildPrimaryXml < ::Packages::Rpm::RepositoryMetadata::BaseBuilder
        ROOT_TAG = 'metadata'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/common',
          'xmlns:rpm': 'http://linux.duke.edu/metadata/rpm',
          packages: '0'
        }.freeze
      end
    end
  end
end
