unless Rails.env.production? # rubocop:disable Naming/FileName
  require 'haml_lint/haml_visitor'
  require 'haml_lint/linter'
  require 'haml_lint/linter_registry'

  module HamlLint
    class Linter::InlineJavaScript < Linter
      include LinterRegistry

      def visit_filter(node)
        return unless node.filter_type == 'javascript'

        record_lint(node, 'Inline JavaScript is discouraged (https://docs.gitlab.com/ee/development/gotchas.html#do-not-use-inline-javascript-in-views)')
      end

      def visit_tag(node)
        return unless node.tag_name == 'script'

        record_lint(node, 'Inline JavaScript is discouraged (https://docs.gitlab.com/ee/development/gotchas.html#do-not-use-inline-javascript-in-views)')
      end
    end
  end
end
