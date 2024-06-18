# frozen_string_literal: true

module RuboCop
  module Cop
    # Check for test coverage for GitLab experiments.
    class ExperimentsTestCoverage < RuboCop::Cop::Base
      CLASS_OFFENSE = 'Make sure experiment class has test coverage for all the variants.'
      BLOCK_OFFENSE = 'Make sure experiment block has test coverage for all the variants.'

      # Validates classes inherited from ApplicationExperiment
      # These classes are located under app/experiments or ee/app/experiments
      def on_class(node)
        return if node.parent_class&.const_name != 'ApplicationExperiment'
        return if covered_with_tests?(node)

        add_offense(node, message: CLASS_OFFENSE)
      end

      # Validates experiments block in *.rb and *.haml files:
      # experiment(:experiment_name) do |e|
      #   e.candidate { 'candidate' }
      #   e.run
      # end
      def on_block(node)
        return if node.method_name != :experiment
        return if covered_with_tests?(node)

        add_offense(node, message: BLOCK_OFFENSE)
      end

      private

      def covered_with_tests?(node)
        tests_code = test_files_code(node)

        return false if tests_code.blank?
        return false unless tests_code.match?(stub_experiments_matcher)
        return false unless tests_code.include?(experiment_name(node))

        experiment_variants(node).map { |variant| tests_code.include?(variant) }.all?(&:present?)
      end

      def test_files_code(node)
        test_file_path = filepath(node).gsub('app/', 'spec/').gsub('.rb', '_spec.rb')
        test_file_path << '_spec.rb' if test_file_path.end_with?('.haml')

        "#{read_file(test_file_path)}\n#{additional_tests_code(test_file_path)}"
      end

      def additional_tests_code(test_file_path)
        if test_file_path.include?('/controllers/')
          read_file(test_file_path.gsub('/controllers/', '/requests/'))
        elsif test_file_path.include?('/lib/api/')
          read_file(test_file_path.gsub('/lib/', '/spec/requests/'))
        end
      end

      def read_file(file_path)
        File.exist?(file_path) ? File.read(file_path) : ''
      end

      def experiment_name(node)
        if node.is_a?(RuboCop::AST::ClassNode)
          File.basename(filepath(node), '_experiment.rb')
        else
          block_node_value(node)
        end
      end

      def experiment_variants(node)
        node.body.children.filter_map do |child|
          next unless child.is_a?(RuboCop::AST::SendNode) || child.is_a?(RuboCop::AST::BlockNode)

          extract_variant(child)
        end
      end

      def extract_variant(node)
        # control enabled by default for tests
        case node.method_name
        when :candidate then 'candidate'
        when :variant then variant_name(node)
        end
      end

      def variant_name(node)
        return send_node_value(node) if node.is_a?(RuboCop::AST::SendNode)

        block_node_value(node)
      end

      def block_node_value(node)
        send_node_value(node.children[0])
      end

      def send_node_value(node)
        node.children[2].value.to_s
      end

      def filepath(node)
        node.location.expression.source_buffer.name
      end

      def stub_experiments_matcher
        # validates test files contains uncommented stub_experiments(...
        /^([^#]|\s*|\w*)stub_experiments\(/
      end
    end
  end
end
