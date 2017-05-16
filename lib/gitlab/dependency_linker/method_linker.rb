module Gitlab
  module DependencyLinker
    class MethodLinker < BaseLinker
      private

      # Links package names in a method call or assignment string argument.
      #
      # Example:
      #   link_method_call('gem')
      #   # Will link `package` in `gem "package"`, `gem("package")` and `gem = "package"`
      #
      #   link_method_call('gem', 'specific_package')
      #   # Will link `specific_package` in `gem "specific_package"`
      #
      #   link_method_call('github', /[^\/"]+\/[^\/"]+/)
      #   # Will link `user/repo` in `github "user/repo"`, but not `github "package"`
      #
      #   link_method_call(%w[add_dependency add_development_dependency])
      #   # Will link `spec.add_dependency "package"` and `spec.add_development_dependency "package"`
      #
      #   link_method_call('name')
      #   # Will link `package` in `self.name = "package"`
      def link_method_call(method_names, value = nil, &url_proc)
        method_names = Array(method_names).map { |name| Regexp.escape(name) }

        value =
          case value
          when String
            Regexp.escape(value)
          when nil
            /[^'"]+/
          else
            value
          end

        regex = %r{
          #{Regexp.union(method_names)} # Method name
          \s*                           # Whitespace
          [(=]?                         # Opening brace or equals sign
          \s*                           # Whitespace
          ['"](?<name>#{value})['"]     # Package name in quotes
        }x

        link_regex(regex, &url_proc)
      end
    end
  end
end
