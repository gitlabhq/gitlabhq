# frozen_string_literal: true

module Gitlab
  module Git
    # Parses root .gitattributes file at a given ref
    class AttributesAtRefParser
      delegate :attributes, to: :@parser

      def initialize(repository, ref)
        blob = repository.blob_at(ref, '.gitattributes')

        @parser = AttributesParser.new(blob&.data)
      end
    end
  end
end
