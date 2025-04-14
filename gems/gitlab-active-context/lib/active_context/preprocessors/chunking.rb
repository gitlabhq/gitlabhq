# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module Chunking
      extend ActiveSupport::Concern

      class_methods do
        def chunk(refs:, chunker:, chunk_on:, field:)
          refs.each do |ref|
            chunker.content = ref.send(chunk_on) # rubocop: disable GitlabSecurity/PublicSend -- method is defined elsewhere

            chunks = chunker.chunks

            ref.documents = chunks.map { |chunk| { "#{field}": chunk } }
          end

          refs
        rescue StandardError => e
          ErrorHandler.log_and_raise_error(e)
        end
      end
    end
  end
end
