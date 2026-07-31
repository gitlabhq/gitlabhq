# frozen_string_literal: true

module HamlLint
  class Linter
    class TemplateFormat < Linter
      include ::HamlLint::LinterRegistry

      DEFAULT_ALLOWED_FORMATS = %w[html text js atom ics xml json csv].freeze

      def visit_root(_node)
        basename = File.basename(document.file.to_s)
        return if basename.match?(/\A.+\.(#{Regexp.union(allowed_formats)})\.haml\z/)

        record_lint(1, message(basename))
      end

      private

      def allowed_formats
        config.fetch('allowed_formats', DEFAULT_ALLOWED_FORMATS)
      end

      def message(basename)
        fixed = basename.sub(/(\.[^.]+)?\.haml\z/, '.html.haml')

        "Filename `#{basename}` is missing a template format. " \
          "Rename it to `#{fixed}`, or use another explicit format " \
          "(#{allowed_formats.join(', ')})"
      end
    end
  end
end
