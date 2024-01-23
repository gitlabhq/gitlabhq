# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Documents
          include Gitlab::Utils::StrongMemoize

          def initialize(documents)
            @documents = documents

            parsed_first_document
          end

          def header
            return unless has_header?

            parsed_first_document
          end

          def content
            return documents.last.raw if has_header?

            documents.first&.raw || ''
          end

          private

          attr_reader :documents

          def has_header?
            return false unless parsed_first_document.is_a?(Hash)

            documents.count > 1 && parsed_first_document.key?(:spec)
          end

          def parsed_first_document
            return {} if documents.count == 0

            documents.first.load!
          end
          strong_memoize_attr :parsed_first_document
        end
      end
    end
  end
end
