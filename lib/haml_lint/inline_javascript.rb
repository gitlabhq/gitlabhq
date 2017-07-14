require 'haml_lint/haml_visitor'
require 'haml_lint/linter'
require 'haml_lint/linter_registry'

module HamlLint
  class Linter::InlineJavaScript < Linter
    include LinterRegistry

    def visit_filter(node)
      return unless node.filter_type == 'javascript'
      record_lint(node, 'Inline JavaScript is discouraged. If needed, you can add this file to the list of exceptions in .haml-lint.yml.')
    end
  end
end
