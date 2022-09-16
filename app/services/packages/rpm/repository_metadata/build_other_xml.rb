# frozen_string_literal: true
module Packages
  module Rpm
    module RepositoryMetadata
      class BuildOtherXml < ::Packages::Rpm::RepositoryMetadata::BaseBuilder
        ROOT_TAG = 'otherdata'
        ROOT_ATTRIBUTES = {
          xmlns: 'http://linux.duke.edu/metadata/other',
          packages: '0'
        }.freeze
      end
    end
  end
end
