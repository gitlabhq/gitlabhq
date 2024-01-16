# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class ReplayEvent
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :issuable_type, :issuable_iid

        def self.from_json_hash(raw_hash)
          new Representation.symbolize_hash(raw_hash)
        end

        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          {
            issuable_type: issuable_type,
            issuable_iid: issuable_iid
          }
        end
      end
    end
  end
end
