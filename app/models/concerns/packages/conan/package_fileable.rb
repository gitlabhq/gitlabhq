# frozen_string_literal: true

module Packages
  module Conan
    module PackageFileable
      extend ActiveSupport::Concern

      included do
        has_many :file_metadata, inverse_of: name.demodulize.underscore.to_sym,
          class_name: 'Packages::Conan::FileMetadatum'
        has_many :package_files, through: :file_metadata

        def orphan?
          package_files.empty?
        end
      end
    end
  end
end
