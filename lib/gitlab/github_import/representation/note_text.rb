# frozen_string_literal: true

# This class only partly represents Release record from DB and
# is used to connect ReleasesAttachmentsImporter, NotesAttachmentsImporter etc.
# with NoteAttachmentsImporter without modifying ObjectImporter a lot.
# Attachments are inside release's `description`.
module Gitlab
  module GithubImport
    module Representation
      class NoteText
        include ToHash
        include ExposeAttribute

        MODELS_WHITELIST = [::Release, ::Note].freeze
        ModelNotSupported = Class.new(StandardError)

        attr_reader :attributes

        expose_attribute :record_db_id, :record_type, :text

        class << self
          # Builds a note text representation from DB record of Note or Release.
          #
          # record - An instance of `Release` or `Note` model.
          def from_db_record(record)
            check_record_class!(record)

            record_type = record.class.name
            text = record.is_a?(Release) ? record.description : record.note
            new(
              record_db_id: record.id,
              record_type: record_type,
              text: text
            )
          end

          def from_json_hash(raw_hash)
            new Representation.symbolize_hash(raw_hash)
          end

          private

          def check_record_class!(record)
            raise ModelNotSupported, record.class.name if MODELS_WHITELIST.exclude?(record.class)
          end
        end

        # attributes - A Hash containing the event details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          { db_id: record_db_id }
        end
      end
    end
  end
end
