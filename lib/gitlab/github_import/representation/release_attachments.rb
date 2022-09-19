# frozen_string_literal: true

# This class only partly represents Release record from DB and
# is used to connect ReleasesAttachmentsImporter with ReleaseAttachmentsImporter
# without modifying ObjectImporter a lot.
# Attachments are inside release's `description`.
module Gitlab
  module GithubImport
    module Representation
      class ReleaseAttachments
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :release_db_id, :description

        # Builds a event from a GitHub API response.
        #
        # release - An instance of `Release` model.
        def self.from_db_record(release)
          new(
            release_db_id: release.id,
            description: release.description
          )
        end

        def self.from_json_hash(raw_hash)
          new Representation.symbolize_hash(raw_hash)
        end

        # attributes - A Hash containing the event details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          { db_id: release_db_id }
        end
      end
    end
  end
end
