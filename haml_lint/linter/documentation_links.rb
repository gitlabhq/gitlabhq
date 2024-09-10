# frozen_string_literal: true

require_relative '../../lib/gitlab/utils/markdown'

module HamlLint
  class Linter
    # This class is responsible for detection of help_page_path helpers
    # with incorrect links or anchors
    class DocumentationLinks < Linter
      include ::HamlLint::LinterRegistry
      include ::Gitlab::Utils::Markdown
      extend ::RuboCop::AST::NodePattern::Macros

      DOCS_DIRECTORY = File.join(File.expand_path('../..', __dir__), 'doc')

      def_node_matcher :help_link, <<~PATTERN
        (send _ {:help_page_url :help_page_path} $...)
      PATTERN

      MARKDOWN_HEADER = %r{\A\#{1,6}\s+(?<header>.+)\Z}

      def visit_script(node)
        check(node)
      end

      def visit_silent_script(node)
        check(node)
      end

      def visit_tag(node)
        check(node)
      end

      private

      def check(node)
        ast_tree = fetch_ast_tree(node)

        return unless ast_tree

        ast_tree.descendants.each do |child_node|
          match = extract_link_and_anchor(child_node)
          validate_node(node, match)
        end
      end

      def validate_node(node, match)
        return if match.empty?

        link = match[:link]

        path_to_file = detect_path_to_file(link)

        unless File.file?(path_to_file)
          record_lint(node, "help_page_path points to the unknown location: #{path_to_file}")
          return
        end

        unless correct_anchor?(path_to_file, match[:anchor])
          record_lint(node, "anchor (#{match[:anchor]}) is missing in: #{path_to_file}")
        end

        record_lint(node, "add .md extension to the link: #{link}") unless link.end_with?('.md')
      end

      def extract_link_and_anchor(ast_tree)
        link_match, attributes_match = help_link(ast_tree)

        { link: fetch_link(link_match), anchor: fetch_anchor(attributes_match) }.compact
      end

      def fetch_ast_tree(node)
        # Sometimes links are provided via data attributes in html tag
        return node.parsed_attributes.syntax_tree if node.type == :tag

        parse_script(node).syntax_tree
      end

      def parse_script(node)
        # It's a workaround for cases for scripts ending with "do"
        # For some reason they don't parse correctly
        code = node.script.delete_suffix(' do')

        HamlLint::ParsedRuby.new(HamlLint::RubyParser.new.parse(code))
      end

      def detect_path_to_file(link)
        path = File.join(DOCS_DIRECTORY, link)
        path += '.md' unless path.end_with?('.md')
        path
      end

      def fetch_link(link_match)
        return unless link_match && link_match.str_type?

        link_match.value
      end

      def fetch_anchor(attributes_match)
        return unless attributes_match

        attributes_match.each_pair do |pkey, pvalue|
          break pvalue.value if pkey.value == :anchor
        end
      end

      def correct_anchor?(path_to_file, anchor)
        return true unless anchor

        File.open(path_to_file).any? do |line|
          result = line.match(MARKDOWN_HEADER)

          string_to_anchor(result[:header]) == anchor if result
        end
      end
    end
  end
end
