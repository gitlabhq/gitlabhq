module Gitlab
  module DependencyLinker
    class BaseLinker
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

      def package_url(name)
        raise NotImplementedError
      end

      def link_dependencies
        raise NotImplementedError
      end

      def package_link(name, url = package_url(name))
        return name unless url

        %{<a href="#{ERB::Util.html_escape_once(url)}" rel="noopener noreferrer" target="_blank">#{ERB::Util.html_escape_once(name)}</a>}
      end

      # Links package names in a method call or assignment string argument.
      #
      # Example:
      #   link_method_call("gem")
      #   # Will link `package` in `gem "package"`, `gem("package")` and `gem = "package"`
      #
      #   link_method_call("gem", "specific_package")
      #   # Will link `specific_package` in `gem "specific_package"`
      #
      #   link_method_call("github", /[^\/]+\/[^\/]+/)
      #   # Will link `user/repo` in `github "user/repo"`, but not `github "package"`
      #
      #   link_method_call(%w[add_dependency add_development_dependency])
      #   # Will link `spec.add_dependency "package"` and `spec.add_development_dependency "package"`
      #
      #   link_method_call("name")
      #   # Will link `package` in `self.name = "package"`
      def link_method_call(method_names, value = nil, &url_proc)
        value =
          case value
          when String
            Regexp.escape(value)
          when nil
            /[^'"]+/
          else
            value
          end

        method_names = Array(method_names).map { |name| Regexp.escape(name) }

        regex = %r{
          #{Regexp.union(method_names)} # Method name
          \s*                           # Whitespace
          [(=]?                         # Opening brace or equals sign
          \s*                           # Whitespace
          ['"](?<name>#{value})['"]     # Package name in quotes
        }x

        link_regex(regex, &url_proc)
      end

      # Links package names based on regex.
      #
      # Example:
      #   link_regex(/(github:|:github =>)\s*['"](?<name>[^'"]+)['"]/)
      #   # Will link `user/repo` in `github: "user/repo"` or `:github => "user/repo"`
      def link_regex(regex)
        highlighted_lines.map!.with_index do |rich_line, i|
          marker = StringRegexMarker.new(plain_lines[i], rich_line.html_safe)

          marker.mark(regex, group: :name) do |text, left:, right:|
            url = block_given? ? yield(text) : package_url(text)
            package_link(text, url)
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
