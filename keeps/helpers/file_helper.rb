# frozen_string_literal: true

require 'rubocop'

module Keeps
  module Helpers
    class FileHelper
      def initialize(file)
        @file = file
        @source = RuboCop::ProcessedSource.from_file(file, RuboCop::ConfigStore.new.for_file('.').target_ruby_version)
        @rewriter = Parser::Source::TreeRewriter.new(@source.buffer)
      end

      class << self
        # Define a node matcher method in the +RuboCop::AST::Node+, which all other node types inherits from.
        def def_node_matcher(method_name, pattern)
          RuboCop::AST::NodePattern.new(pattern).def_node_matcher(RuboCop::AST::Node, method_name)

          define_method method_name do
            source.ast.public_send(method_name) # rubocop:disable GitlabSecurity/PublicSend -- it's used to evaluate the node matcher at instance level
          end
        end
      end

      def replace_method_content(method_name, content, strip_comments_from_file: false)
        method = source.ast.each_node(:class).first.each_node(:def).find do |child|
          child.method_name == method_name.to_sym
        end

        rewriter.replace(method.loc.expression, content)

        strip_comments if strip_comments_from_file

        File.write(file, process)

        process
      end

      def replace_as_string(node, content)
        rewriter.replace(node.loc.expression, content)

        process
      end

      private

      attr_reader :file, :source, :rewriter, :corrector

      # Strip comments from the source file, except the for frozen_string_literal: true
      def strip_comments
        source.comments.each do |comment|
          next if comment.text.include?('frozen_string_literal: true')

          rewriter.remove(comment_range(comment))
        end
      end

      # Finds the proper range for the comment.
      #
      # @Note inline comments can cause trailing whitespaces.
      #       For such cases, the extra whitespace needs to be removed
      def comment_range(comment)
        range = comment.loc.expression
        adjusted_range = range.adjust(begin_pos: -1)

        return range if comment.document?

        adjusted_range.source.start_with?(' ') ? adjusted_range : range
      end

      def process
        rewriter.process.lstrip.gsub(/\n{3,}/, "\n\n")
      end
    end
  end
end
