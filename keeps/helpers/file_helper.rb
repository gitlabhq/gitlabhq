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

      def replace_method_content(method_name, content, strip_comments_from_file: false)
        method = source.ast.each_node(:class).first.each_node(:def).find do |child|
          child.method_name == method_name.to_sym
        end

        rewriter.replace(method.loc.expression, content)

        strip_comments if strip_comments_from_file

        File.write(file, process)

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
        @process ||= rewriter.process.lstrip.gsub(/\n{3,}/, "\n\n")
      end
    end
  end
end
