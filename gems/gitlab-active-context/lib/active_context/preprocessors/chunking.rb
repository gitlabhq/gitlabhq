# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module Chunking
      extend ActiveSupport::Concern

      ChunkingError = Class.new(StandardError)

      class_methods do
        def chunk(refs:, chunker:, chunk_on:, field:)
          return { successful: [], failed: [] } if refs.empty?

          result = with_batch_handling(refs) do
            raise ChunkingError, "Chunker must respond to :chunks method" unless chunker.respond_to?(:chunks)

            refs
          end

          return result if result[:failed].any?

          with_per_ref_handling(refs) do |ref|
            chunker.content = ref.send(chunk_on) # rubocop: disable GitlabSecurity/PublicSend -- method is defined elsewhere

            chunks = chunker.chunks

            ref.documents = chunks.map { |chunk| { "#{field}": chunk } }
          end
        end
      end
    end
  end
end
