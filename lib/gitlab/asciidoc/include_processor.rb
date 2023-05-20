# frozen_string_literal: true

require 'asciidoctor/include_ext/include_processor'

module Gitlab
  module Asciidoc
    # Asciidoctor extension for processing includes (macro include::[]) within
    # documents inside the same repository.
    class IncludeProcessor < Asciidoctor::IncludeExt::IncludeProcessor
      extend ::Gitlab::Utils::Override

      NoData = Class.new(StandardError)

      def initialize(context)
        super(logger: Gitlab::AppLogger)

        @context = context
        @repository = context[:repository] || context[:project].try(:repository)
        @max_includes = context[:max_includes].to_i
        @included = []
        @included_content = {}

        # Note: Asciidoctor calls #freeze on extensions, so we can't set new
        # instance variables after initialization.
        @cache = {
            uri_types: {}
        }
      end

      protected

      override :include_allowed?
      def include_allowed?(target, reader)
        doc = reader.document

        max_include_depth = doc.attributes.fetch('max-include-depth').to_i
        allow_uri_read = doc.attributes.fetch('allow-uri-read', false)

        return false if max_include_depth < 1
        return false if target_http?(target) && !allow_uri_read
        return false if included.size >= max_includes

        true
      end

      override :resolve_target_path
      def resolve_target_path(target, reader)
        return unless repository.try(:exists?)
        return target if target_http?(target)

        base_path = reader.include_stack.empty? ? requested_path : reader.file
        path = resolve_relative_path(target, base_path)

        path if Gitlab::Git::Blob.find(repository, ref, path)
      end

      override :read_lines
      def read_lines(filename, selector)
        content = read_content(filename)
        raise NoData, filename if content.nil?

        included << filename

        if selector
          content.each_line.select.with_index(1, &selector)
        else
          content.lines
        end
      end

      override :unresolved_include!
      def unresolved_include!(target, reader)
        reader.unshift_line("*[ERROR: include::#{target}[] - unresolved directive]*")
      end

      private

      attr_reader :context, :repository, :cache, :max_includes, :included, :included_content

      def read_content(filename)
        return included_content[filename] if included_content.key?(filename)

        included_content[filename] = if target_http?(filename)
                                       read_uri(filename)
                                     else
                                       read_blob(ref, filename)
                                     end
      end

      # Gets a Blob at a path for a specific revision.
      # This method will check that the Blob exists and contains readable text.
      #
      # revision - The String SHA1.
      # path     - The String file path.
      #
      # Returns a string containing the blob content
      def read_blob(ref, filename)
        blob = repository&.blob_at(ref, filename)

        raise NoData, 'Blob not found' unless blob
        raise NoData, 'File is not readable' unless blob.readable_text?

        blob.data
      end

      def read_uri(uri)
        r = Gitlab::HTTP.get(uri)

        raise NoData, uri unless r.success?

        r.body
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

      def current_commit
        cache[:current_commit] ||= context[:commit] || repository&.commit(ref)
      end

      def ref
        context[:ref] || repository&.root_ref
      end

      def requested_path
        cache[:requested_path] ||= Addressable::URI.unescape(context[:requested_path])
      end

      def uri_type(path)
        cache[:uri_types][path] ||= current_commit&.uri_type(path)
      end
    end
  end
end
