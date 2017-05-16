module Gitlab
  module DependencyLinker
    class BaseLinker
      URL_REGEX = %r{https?://[^'"]+}.freeze

      class_attribute :file_type

      def self.support?(blob_name)
        Gitlab::FileDetector.type_of(blob_name) == file_type
      end

      def self.link(*args)
        new(*args).link
      end

      attr_accessor :plain_text, :highlighted_text

      def initialize(plain_text, highlighted_text)
        @plain_text = plain_text
        @highlighted_text = highlighted_text
      end

      def link
        link_dependencies

        highlighted_lines.join.html_safe
      end

      private

      def link_dependencies
        raise NotImplementedError
      end

      def license_url(name)
        Licensee::License.find(name)&.url
      end


      def link_tag(name, url)
        %{<a href="#{ERB::Util.html_escape_once(url)}" rel="nofollow noreferrer noopener" target="_blank">#{ERB::Util.html_escape_once(name)}</a>}
      end

      # Links package names based on regex.
      #
      # Example:
      #   link_regex(/(github:|:github =>)\s*['"](?<name>[^'"]+)['"]/)
      #   # Will link `user/repo` in `github: "user/repo"` or `:github => "user/repo"`
      def link_regex(regex, &url_proc)
        highlighted_lines.map!.with_index do |rich_line, i|
          marker = StringRegexMarker.new(plain_lines[i], rich_line.html_safe)

          marker.mark(regex, group: :name) do |text, left:, right:|
            url = yield(text)
            url ? link_tag(text, url) : text
          end
        end
      end

      def plain_lines
        @plain_lines ||= plain_text.lines
      end

      def highlighted_lines
        @highlighted_lines ||= highlighted_text.lines
      end
    end
  end
end
