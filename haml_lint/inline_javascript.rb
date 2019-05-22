# frozen_string_literal: true

unless Rails.env.production?
  require_dependency 'haml_lint/haml_visitor'
  require_dependency 'haml_lint/linter'
  require_dependency 'haml_lint/linter_registry'

  module HamlLint
    class Linter::InlineJavaScript < Linter
      include ::HamlLint::LinterRegistry

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
