# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Detect wrong use of condition scope.
      #
      # @example
      #   # bad
      #   condition(:admin, scope: :global) { @user.admin? }
      #   condition(:closed, scope: :user) { @subject.closed? }
      #   condition(:blocked, scope: :subject) { @user.blocked? }
      #   condition(:unrelated, scope: :subject) { @another }
      #
      #   # good
      #   condition(:admin) { @user.admin? }
      #   condition(:closed, scope: :subject) { @subject.closed? }
      #   condition(:blocked, scope: :user) { @user.blocked? }
      #   condition(:unrelated) { @another }
      class PolicyConditionScope < RuboCop::Cop::Base
        MSG = 'Scope `%<scope>s` uses disallowed references: `%<references>s`. See https://docs.gitlab.com/development/policies/#scope'

        SCOPE_ALLOWED_REFERENCES = {
          subject: %i[@subject subject],
          user: %i[@user user],
          global: []
        }.freeze

        # Class-level cache for parsed policy files
        # Structure: { file_path => { subject_aliases: [], user_aliases: [], safe_predicates: [] } }
        @parsed_files_cache = {}

        class << self
          attr_accessor :parsed_files_cache

          def clear_cache
            @parsed_files_cache = {}
          end
        end

        # @!method scope_from_hash_arg(node)
        def_node_matcher :scope_from_hash_arg, <<~PATTERN
        (hash <(pair (sym :scope) $(sym $_)) ...>)
        PATTERN

        def on_new_investigation
          @subject_aliases = []
          @user_aliases = []
          @blocks_to_check = []
          @safe_predicates = []

          current_class_node = processed_source.ast.each_node(:class).first
          parent_class_name = find_superclass_name(current_class_node)

          ce_class_name = extract_policy_name
          if ce_class_name
            path = resolve_parent_file_path(ce_class_name)
            load_parent_policy_aliases(path) if path
          end

          # Load aliases from parent class, if found in app/policies/
          if parent_class_name
            path = resolve_parent_file_path(parent_class_name)
            load_parent_policy_aliases(path) if path
          end

          processed_source.ast.each_node do |node|
            case node.type
            when :def
              process_def(node, @subject_aliases, @user_aliases, @safe_predicates)
            when :send
              process_alias_method(node, @subject_aliases, @user_aliases) if node.method?(:alias_method)
            when :block, :numblock
              @blocks_to_check << node
            end
          end

          blocks_to_check
        end

        private

        def blocks_to_check
          @blocks_to_check.each do |block_node|
            send_node = block_node.send_node

            if send_node.method?(:condition)
              scope = extract_scope_from_args(send_node.arguments)
              check_block(block_node, scope)
            end
          end
        end

        def extract_policy_name
          return unless processed_source.path&.start_with?(File.join(Dir.pwd, 'ee'))

          policy_name = nil
          processed_source.ast.each_descendant(:module).reverse_each do |mod_node|
            policy_name = extract_const_basename(mod_node.children[0])
            break if policy_name&.end_with?('Policy')
          end
          policy_name
        end

        def extract_const_basename(node)
          return unless node

          if node.const_type?
            node = node.children[0] while node.children[1] && node.children[0]&.const_type?
            return node.children[1].to_s
          end

          nil
        end

        def used_in_condition?(node)
          parent = node.parent
          return false unless parent

          case parent.type
          when :if, :elsif, :unless
            parent.condition == node
          else
            false
          end
        end

        def boolean_literal?(body_node)
          %i[true false].include?(body_node.type)
        end

        def find_superclass_name(class_node)
          superclass = class_node&.children&.at(1)
          return unless superclass&.const_type?

          superclass.const_name
        end

        def resolve_parent_file_path(class_name)
          relative_path = "#{class_name.gsub('::', '/')
                            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                            .downcase}.rb"

          search_dirs = %w[app/policies ee/app/policies]
          search_dirs.each do |dir|
            full_path = File.join(Dir.pwd, dir, relative_path)
            return full_path if File.exist?(full_path)
          end

          nil
        end

        def load_parent_policy_aliases(path)
          cached_data = get_or_parse_policy_file(path)
          return unless cached_data

          @subject_aliases.concat(cached_data[:subject_aliases])
          @user_aliases.concat(cached_data[:user_aliases])
          @safe_predicates.concat(cached_data[:safe_predicates])

          # Ensure uniqueness after concatenation
          @subject_aliases.uniq!
          @user_aliases.uniq!
          @safe_predicates.uniq!
        end

        def get_or_parse_policy_file(path)
          # Check if we've already parsed this file
          cache = self.class.parsed_files_cache

          return cache[path] if cache.key?(path)

          # Parse the file and cache the results
          data = parse_policy_file(path)
          cache[path] = data if data

          data
        end

        def parse_policy_file(path)
          source = RuboCop::ProcessedSource.from_file(path, RUBY_VERSION.to_f)
          return unless source&.ast

          subject_aliases = []
          user_aliases = []
          safe_predicates = []

          source.ast.each_node(:def) do |node|
            process_def(node, subject_aliases, user_aliases, safe_predicates)
          end

          source.ast.each_node(:send) do |node|
            process_alias_method(node, subject_aliases, user_aliases) if node.method?(:alias_method)
          end

          {
            subject_aliases: subject_aliases.uniq,
            user_aliases: user_aliases.uniq,
            safe_predicates: safe_predicates.uniq
          }
        end

        def process_def(node, subject_aliases, user_aliases, safe_predicates)
          return unless node.body

          method_name = node.method_name
          ivars = [node.body, *node.body.each_descendant].select(&:ivar_type?).map { |n| n.children.first }

          return if ivars.include?(:@user) && ivars.include?(:@subject)

          subject_aliases << method_name if ivars.include?(:@subject) && !subject_aliases.include?(method_name)
          user_aliases << method_name if ivars.include?(:@user) && !user_aliases.include?(method_name)
          safe_predicates << method_name if boolean_literal?(node.body) && !safe_predicates.include?(method_name)
        end

        def process_alias_method(node, subject_aliases, user_aliases)
          args = node.arguments
          return unless args.size == 2

          alias_name, original_name = args.map { |arg| arg.value if arg.sym_type? }

          case original_name
          when :subject
            subject_aliases << alias_name unless subject_aliases.include?(alias_name)
          when :user
            user_aliases << alias_name unless user_aliases.include?(alias_name)
          end
        end

        def extract_scope_from_args(args)
          args.each do |arg|
            scope_node, scope_value = scope_from_hash_arg(arg)
            return [scope_node, scope_value] if scope_value
          end

          [nil, nil]
        end

        def allowed_references_for(scope)
          case scope
          when :subject
            SCOPE_ALLOWED_REFERENCES[:subject] + @subject_aliases
          when :user
            SCOPE_ALLOWED_REFERENCES[:user] + @user_aliases
          else
            []
          end
        end

        def check_block(block_node, _scope)
          scope_node, scope = extract_scope_from_args(block_node.send_node.arguments)
          return unless SCOPE_ALLOWED_REFERENCES.key?(scope)

          used_references = extract_references(block_node)
          allowed_references = allowed_references_for(scope)
          disallowed = used_references - allowed_references

          return if disallowed.empty?

          add_offense(scope_node || block_node.send_node,
            message: format(MSG, scope: scope, references: disallowed.join(', ')))
        end

        def extract_references(block_node)
          return [] unless block_node.body

          ivars = block_node.each_descendant(:ivar).map { |n| n.children.first }
          method_calls = block_node.body.each_descendant(:send)
            .select { |n| n.receiver.nil? && n.arguments.empty? && !used_in_condition?(n) }
            .map(&:method_name)
            .reject { |name| @safe_predicates.include?(name) }

          (ivars + method_calls).uniq
        end
      end
    end
  end
end
