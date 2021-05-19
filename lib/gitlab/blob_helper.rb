# frozen_string_literal: true

# This has been extracted from https://github.com/github/linguist/blob/master/lib/linguist/blob_helper.rb
module Gitlab
  module BlobHelper
    include Gitlab::Utils::StrongMemoize

    def extname
      File.extname(name.to_s)
    end

    def known_extension?
      LanguageData.extensions.include?(extname)
    end

    def viewable?
      !large? && text_in_repo?
    end

    MEGABYTE = 1024 * 1024

    def large?
      size.to_i > MEGABYTE
    end

    def binary_in_repo?
      # Large blobs aren't even loaded into memory
      if data.nil?
        true

      # Treat blank files as text
      elsif data == ""
        false

      # Charlock doesn't know what to think
      elsif encoding.nil?
        true

      # If Charlock says its binary
      else
        find_encoding[:type] == :binary
      end
    end

    def text_in_repo?
      !binary_in_repo?
    end

    def image?
      ['.png', '.jpg', '.jpeg', '.gif', '.svg'].include?(extname.downcase)
    end

    # Internal: Lookup mime type for extension.
    #
    # Returns a MIME::Type
    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def _mime_type
      if defined? @_mime_type
        @_mime_type
      else
        guesses = ::MIME::Types.type_for(extname.to_s)

        # Prefer text mime types over binary
        @_mime_type = guesses.detect { |type| type.ascii? } || guesses.first
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    # Public: Get the actual blob mime type
    #
    # Examples
    #
    #   # => 'text/plain'
    #   # => 'text/html'
    #
    # Returns a mime type String.
    def mime_type
      _mime_type ? _mime_type.to_s : 'text/plain'
    end

    def binary_mime_type?
      _mime_type ? _mime_type.binary? : false
    end

    def lines
      @lines ||=
        if viewable? && data
          # `data` is usually encoded as ASCII-8BIT even when the content has
          # been detected as a different encoding. However, we are not allowed
          # to change the encoding of `data` because we've made the implicit
          # guarantee that each entry in `lines` is encoded the same way as
          # `data`.
          #
          # Instead, we re-encode each possible newline sequence as the
          # detected encoding, then force them back to the encoding of `data`
          # (usually a binary encoding like ASCII-8BIT). This means that the
          # byte sequence will match how newlines are likely encoded in the
          # file, but we don't have to change the encoding of `data` as far as
          # Ruby is concerned. This allows us to correctly parse out each line
          # without changing the encoding of `data`, and
          # also--importantly--without having to duplicate many (potentially
          # large) strings.
          begin
            data.split(encoded_newlines_re, -1)
          rescue Encoding::ConverterNotFoundError
            # The data is not splittable in the detected encoding.  Assume it's
            # one big line.
            [data]
          end
        else
          []
        end
    end

    def content_type
      # rubocop:disable Style/MultilineTernaryOperator
      # rubocop:disable Style/NestedTernaryOperator
      @content_type ||= binary_mime_type? || binary_in_repo? ? mime_type :
                          (encoding ? "text/plain; charset=#{encoding.downcase}" : "text/plain")
      # rubocop:enable Style/NestedTernaryOperator
      # rubocop:enable Style/MultilineTernaryOperator
    end

    def encoded_newlines_re
      strong_memoize(:encoded_newlines_re) do
        newlines = ["\r\n", "\r", "\n"]
        data_encoding = data&.encoding

        if ruby_encoding && data_encoding
          newlines.map! do |nl|
            nl.encode(ruby_encoding, "ASCII-8BIT").force_encoding(data_encoding)
          end
        end

        Regexp.union(newlines)
      end
    end

    def ruby_encoding
      if hash = find_encoding
        hash[:ruby_encoding]
      end
    end

    def encoding
      if hash = find_encoding
        hash[:encoding]
      end
    end

    def empty?
      data.nil? || data == ""
    end

    private

    def find_encoding
      @find_encoding ||= Gitlab::EncodingHelper.detect_encoding(data) if data # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end
  end
end
