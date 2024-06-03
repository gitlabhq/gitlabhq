# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class LfsObject
        include Representable

        expose_attribute :oid, :link, :size, :headers

        # Builds a lfs_object
        def self.from_api_response(lfs_object, additional_data = {})
          new(
            oid: lfs_object.oid,
            link: lfs_object.link,
            size: lfs_object.size,
            headers: lfs_object.headers
          )
        end

        # Builds a new lfs_object using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          new(Representation.symbolize_hash(raw_hash))
        end

        # attributes - A Hash containing the raw lfs_object details. The keys of this
        #              Hash must be Symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          {
            oid: oid,
            size: size
          }
        end
      end
    end
  end
end
