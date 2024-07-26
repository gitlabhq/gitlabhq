# frozen_string_literal: true

module Gitlab
  module WikiPages
    class FrontMatterParser
      # We limit the maximum length of text we are prepared to parse as YAML, to
      # avoid exploitations and attempts to consume memory and CPU. We allow for:
      #  - a title line
      #  - a "slugs:" line
      #  - and up to 50 slugs
      #
      # This limit does not take comments into account.
      MAX_SLUGS = 50
      SLUG_LINE_LENGTH = (4 + Gitlab::WikiPages::MAX_DIRECTORY_BYTES + 1 + Gitlab::WikiPages::MAX_TITLE_BYTES)
      MAX_FRONT_MATTER_LENGTH = (8 + Gitlab::WikiPages::MAX_TITLE_BYTES) + 7 + (SLUG_LINE_LENGTH * MAX_SLUGS)

      ParseError = Class.new(StandardError)

      class Result
        attr_reader :front_matter, :content, :reason, :error

        def initialize(content:, front_matter: {}, reason: nil, error: nil)
          @content      = content
          @front_matter = front_matter.freeze
          @reason       = reason
          @error        = error
        end
      end

      # @param [String] wiki_content
      def initialize(wiki_content)
        @wiki_content = wiki_content
      end

      def parse
        return empty_result unless wiki_content.present?
        return empty_result(block.error) unless block.valid?

        Result.new(front_matter: block.data, content: strip_front_matter_block)
      rescue ParseError => error
        empty_result(:parse_error, error)
      end

      class Block
        include Gitlab::Utils::StrongMemoize

        def initialize(delim = nil, lang = '', text = nil)
          @lang = lang&.downcase.presence || Gitlab::FrontMatter::DELIM_LANG[delim]
          @text = text&.strip!
        end

        def data
          @data ||= YAML.safe_load(text, symbolize_names: true)
        rescue Psych::DisallowedClass, Psych::SyntaxError => error
          raise ParseError, error.message
        end

        def valid?
          error.nil?
        end

        def error
          strong_memoize(:error) { no_match? || too_long? || not_yaml? || not_mapping? }
        end

        private

        attr_reader :lang, :text

        def no_match?
          :no_match if text.nil?
        end

        def not_yaml?
          :not_yaml if lang != 'yaml'
        end

        def too_long?
          :too_long if text.size > MAX_FRONT_MATTER_LENGTH
        end

        def not_mapping?
          :not_mapping unless data.is_a?(Hash)
        end
      end

      private

      attr_reader :wiki_content

      def empty_result(reason = nil, error = nil)
        Result.new(content: wiki_content, reason: reason, error: error)
      end

      def block
        @block ||= parse_front_matter_block
      end

      def parse_front_matter_block
        if match = Gitlab::FrontMatter::PATTERN_UNTRUSTED_REGEX.match(wiki_content)
          Block.new(match[:delim], match[:lang], match[:front_matter])
        else
          Block.new
        end
      end

      def strip_front_matter_block
        Gitlab::FrontMatter::PATTERN_UNTRUSTED_REGEX.replace_gsub(wiki_content) do
          ''
        end
      end
    end
  end
end
