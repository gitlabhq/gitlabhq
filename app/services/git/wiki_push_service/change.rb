# frozen_string_literal: true

module Git
  class WikiPushService
    class Change
      include Gitlab::Utils::StrongMemoize

      # @param [Wiki] wiki
      # @param [Hash] change - must have keys `:oldrev` and `:newrev`
      # @param [Gitlab::Git::RawDiffChange] raw_change
      def initialize(wiki, change, raw_change)
        @wiki = wiki
        @raw_change = raw_change
        @change = change
      end

      def page
        strong_memoize(:page) { wiki.find_page(slug, revision) }
      end

      # See [Gitlab::Git::RawDiffChange#extract_operation] for the
      # definition of the full range of operation values.
      def event_action
        case raw_change.operation
        when :added
          :created
        when :deleted
          :destroyed
        else
          :updated
        end
      end

      def last_known_slug
        strip_extension(raw_change.old_path || raw_change.new_path)
      end

      def sha
        change[:newrev]
      end

      private

      attr_reader :raw_change, :change, :wiki

      def filename
        return raw_change.old_path if deleted?

        raw_change.new_path
      end

      def slug
        strip_extension(filename)
      end

      def revision
        return change[:oldrev] if deleted?

        change[:newrev]
      end

      def deleted?
        raw_change.operation == :deleted
      end

      def strip_extension(filename)
        return unless filename

        encoded_filename = Gitlab::EncodingHelper.encode_utf8(filename.dup)
        File.basename(encoded_filename, File.extname(encoded_filename))
      end
    end
  end
end
