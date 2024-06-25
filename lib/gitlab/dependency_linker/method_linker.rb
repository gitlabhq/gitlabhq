# frozen_string_literal: true

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
      def link_method_call(method_name, value = nil, &url_proc)
        regex = method_call_regex(method_name, value)

        link_regex(regex, &url_proc)
      end

      def method_call_regex(method_name, value = nil)
        method_name = regexp_for_value(method_name)
        value = regexp_for_value(value)

        %r{
        (?:^\s{0,10}(?:[a-z_.]{1,100}\.)?)\K # Look behind newline + whitespace + yielded object e.g. `spec.`
          #{method_name}                    # Method name
          \s{0,50}                          # Whitespace
          (?:[(=]\s{0,50})?                 # ( or = + whitespace
          ['"](?<name>#{value})['"]         # Package name in quotes
        }x
      end
    end
  end
end
