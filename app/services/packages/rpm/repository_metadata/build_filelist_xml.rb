# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildFilelistXml < ::Packages::Rpm::RepositoryMetadata::BaseBuilder
        ROOT_TAG = 'filelists'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/filelists',
          packages: '0'
        }.freeze
      end
    end
  end
end
