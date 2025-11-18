# frozen_string_literal: true

module RuboCop
  module Cop
    # Check for test coverage for GitLab experiments.
    class ExperimentsTestCoverage < RuboCop::Cop::Base
      CLASS_OFFENSE = 'Make sure experiment class has test coverage for all the variants.'
      BLOCK_OFFENSE = 'Make sure experiment block has test coverage for all the variants.'
      SHARED_EXAMPLE_METHODS = %w[include_examples it_behaves_like it_should_behave_like].freeze

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
        return unless node.method?(:experiment)
        return if covered_with_tests?(node)

        add_offense(node, message: BLOCK_OFFENSE)
      end

      private

      def covered_with_tests?(node)
        tests_code = test_files_code

        return false if tests_code.blank?
        return false unless tests_code.match?(stub_experiments_matcher)
        return false unless tests_code.include?(experiment_name(node))

        experiment_variants(node).map { |variant| tests_code.include?(variant) }.all?(&:present?)
      end

      def test_files_code
        # "/ee/spec/services/registrations/base_namespace_create_service_spec.rb"
        test_file_path = filepath.gsub('app/', 'spec/').gsub('.rb', '_spec.rb')
        test_file_path << '_spec.rb' if test_file_path.end_with?('.haml')

        test_code = "#{read_file(test_file_path)}\n#{outside_app_tests_code(test_file_path)}\n#{directory_tests_code(
          test_file_path)}"

        return test_code unless shared_examples?(test_code)

        test_code << shared_examples_tests_code(test_code)
      end

      def outside_app_tests_code(test_file_path)
        if test_file_path.include?('/controllers/')
          read_file(test_file_path.gsub('/controllers/', '/requests/'))
        elsif test_file_path.include?('/lib/api/') # api tests in lib folder
          read_file(test_file_path.gsub('/lib/', '/spec/requests/'))
        elsif test_file_path.include?('/lib/') # other tests in lib folder
          read_file(test_file_path.gsub('/lib/', '/spec/lib/'))
        end
      end

      def read_file(file_path)
        File.exist?(file_path) ? File.read(file_path) : ''
      end

      def experiment_name(node)
        if node.is_a?(RuboCop::AST::ClassNode)
          File.basename(filepath, '_experiment.rb')
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

      def filepath
        processed_source.file_path
      end

      def stub_experiments_matcher
        # validates test files contains uncommented stub_experiments(...
        /^([^#]|\s*|\w*)stub_experiments\(/
      end

      def base_class?
        File.basename(filepath).start_with?('base_') && File.basename(filepath).end_with?('.rb')
      end

      def directory_tests_code(test_file_path)
        return '' unless base_class?

        test_directory_path = File.dirname(test_file_path)
        return '' unless Dir.exist?(test_directory_path)

        child_test_files = +""

        Dir.children(test_directory_path).each do |child_test|
          next unless child_test.end_with?('_spec.rb')

          child_test_files << "#{read_file(File.join(test_directory_path, child_test))}\n"
        end

        child_test_files
      end

      def shared_examples?(test_code)
        SHARED_EXAMPLE_METHODS.any? { |method| test_code.include?(method) }
      end

      def shared_examples_tests_code(test_code)
        example_names = shared_example_names(test_code)

        shared_example_files = Dir.glob('spec/support/shared_examples/**/*.rb') +
          Dir.glob('ee/spec/support/shared_examples/**/*.rb')

        shared_example_files_code = +""
        shared_example_files.each do |file|
          code = read_file(file)

          next unless example_names.any? do |example_name|
            code.match?(/shared_(?:examples?(?:_for)?|context)\s+['"]#{Regexp.escape(example_name)}['"]/)
          end

          shared_example_files_code << "#{code}\n"
        end

        shared_example_files_code
      end

      def shared_example_names(test_code)
        names = []

        SHARED_EXAMPLE_METHODS.each do |method|
          # E.g. extract `shared example name` from `it_behaves_like 'shared example name'`
          test_code.scan(/#{method}\s+['"]([^'"]+)['"]/) do |match|
            names << match[0]
          end
        end

        names.uniq
      end
    end
  end
end
