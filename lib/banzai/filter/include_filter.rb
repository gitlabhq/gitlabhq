# frozen_string_literal: true

module Banzai
  module Filter
    # Detect include / transclusion syntax. Include the specified file/url, replacing
    # the existing include instruction with the contents of the file/url.
    # - does not recursively handle includes
    # - only supports wikis or repository files
    #
    # Syntax is `::include{file=FILE_OR_URL}`
    #
    # Based on lib/gitlab/asciidoc/include_processor.rb
    class IncludeFilter < HTML::Pipeline::TextFilter
      include Gitlab::Utils::StrongMemoize

      # This regex must be able to handle `\n` or `\r\n` line endings
      REGEX = Regexp.new('^::include\{file=(?<include>.{1,1024})}([\r\n]?$|\z)',
        timeout: Banzai::Filter::Concerns::TimeoutFilterHandler::RENDER_TIMEOUT)

      def call
        return text unless wiki? || blob?

        @included_content = {}
        @total_included = 0

        @text = Gitlab::Utils::Gsub.gsub_with_limit(@text, REGEX, limit: max_includes) do |match_data|
          filename = match_data[:include]

          if filename
            read_lines(filename)
          else
            match_data[0]
          end
        end

        @text = Banzai::Filter::TruncateSourceFilter.new(@text, context).call if @total_included > 0

        @text
      end

      private

      attr_reader :included_content

      def include_allowed?(filename)
        return false if target_http?(filename) && !allow_uri_read

        true
      end

      def read_lines(filename)
        return markdown_link(filename) unless include_allowed?(filename)

        content = read_content(filename)
        return '' if content.nil?

        @total_included += 1

        content
      end

      def read_content(filename)
        return included_content[filename] if included_content.key?(filename)

        included_content[filename] = if target_http?(filename)
                                       read_uri(filename)
                                     else
                                       read_blob(ref, filename)
                                     end
      end

      # Gets Blob at a path for a specific revision.
      # This method will check that the Blob exists and contains readable text.
      #
      # revision - The String SHA1.
      # path     - The String file path.
      #
      # Returns a string containing the blob content
      def read_blob(ref, filename)
        return error_message(filename, 'no repository') unless repository.try(:exists?)

        target = resolve_target_path(filename)

        return error_message(filename, 'not found') unless target

        blob = repository&.blob_at(ref, target)

        return error_message(filename, 'not found') unless blob
        return error_message(filename, 'not readable') unless blob.readable_text?

        if wiki?
          Gitlab::WikiPages::FrontMatterParser.new(blob.data).parse.content
        else
          blob.data
        end
      end

      def read_uri(uri)
        r = Gitlab::HTTP.get(uri)

        return error_message(uri, 'not readable') unless r.success?

        r.body
      end

      def target_http?(target)
        # First do a fast test, then try to parse it.
        target.downcase.start_with?('http://', 'https://') && URI.parse(target).is_a?(URI::HTTP)
      rescue URI::InvalidURIError
        false
      end

      def resolve_target_path(filename)
        return unless requested_path

        path = resolve_relative_path(filename, requested_path)

        path if Gitlab::Git::Blob.find(repository, ref, path)
      end

      # Resolves the given relative path of file in repository into canonical
      # path based on the specified base_path.
      #
      # Examples:
      #
      #   # File in the same directory as the current path
      #   resolve_relative_path("users.adoc", "doc/api/README.adoc")
      #   # => "doc/api/users.adoc"
      #
      #   # File in the same directory, which is also the current path
      #   resolve_relative_path("users.adoc", "doc/api")
      #   # => "doc/api/users.adoc"
      #
      #   # Going up one level to a different directory
      #   resolve_relative_path("../update/7.14-to-8.0.adoc", "doc/api/README.adoc")
      #   # => "doc/update/7.14-to-8.0.adoc"
      #
      # Returns a String
      def resolve_relative_path(path, base_path)
        p = Pathname(base_path)
        p = p.dirname unless p.extname.empty?
        p += path

        p.cleanpath.to_s
      end

      def ref
        context[:ref] || repository&.root_ref
      end
      strong_memoize_attr :ref

      def requested_path
        Addressable::URI.unescape(context[:requested_path])
      end
      strong_memoize_attr :requested_path

      def allow_uri_read
        Gitlab::CurrentSettings.wiki_asciidoc_allow_uri_includes
      end
      strong_memoize_attr :allow_uri_read

      def max_includes
        [::Gitlab::CurrentSettings.asciidoc_max_includes, context[:max_includes]].compact.min
      end
      strong_memoize_attr :max_includes

      def repository
        context[:repository] || context[:project].try(:repository)
      end
      strong_memoize_attr :repository

      def wiki?
        !context[:wiki].nil?
      end

      def blob?
        context[:text_source] == :blob
      end

      def markdown_link(url)
        "[#{url}](#{url})"
      end

      def error_message(filename, reason)
        "**Error including '#{markdown_link(filename)}' : #{reason}**\n"
      end
    end
  end
end
