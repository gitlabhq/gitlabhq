# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Detect wrong use of condition scope across all declaration patterns:
        # inline `scope:`, `with_scope`, and `with_options scope:`.
        #
        # @example
        #   # bad -with_scope :subject but references @user
        #   with_scope :subject
        #   condition(:forking_allowed) { @subject.feature_available?(:forking, @user) }
        #
        #   # bad -with_options scope: :user but references @subject
        #   with_options scope: :user
        #   condition(:closed) { @subject.closed? }
        #
        #   # bad -inline scope: :global but references @user
        #   condition(:admin, scope: :global) { @user.admin? }
        #
        #   # good
        #   with_scope :subject
        #   condition(:closed) { @subject.closed? }
        #
        #   # good
        #   with_options scope: :user, score: 0
        #   condition(:admin) { @user.admin? }
        #
        #   # good -inline scope
        #   condition(:closed, scope: :subject) { @subject.closed? }
        class ConditionScope < RuboCop::Cop::Base
          SCOPE_CACHE_DESCRIPTION = {
            subject: 'per-subject',
            user: 'per-user',
            global: 'globally'
          }.freeze

          MSG = 'Scope `%<scope>s` caches %<cache_desc>s but `%<references>s` was referenced. ' \
            'This causes cache bugs. Remove the scope or the disallowed references. ' \
            'See https://docs.gitlab.com/development/policies/#scope'

          VALID_SCOPES = %i[subject user global].freeze

          SCOPE_ALLOWED_REFERENCES = {
            subject: %i[@subject subject],
            user: %i[@user user],
            global: []
          }.freeze

          # Class-level cache for parsed policy files
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

          # @!method with_scope_call?(node)
          def_node_matcher :with_scope_call?, <<~PATTERN
            (send nil? :with_scope (sym $_))
          PATTERN

          # @!method with_options_scope(node)
          def_node_matcher :with_options_scope, <<~PATTERN
            (send nil? :with_options (hash <(pair (sym :scope) $(sym $_)) ...>))
          PATTERN

          def on_new_investigation
            @subject_aliases = []
            @user_aliases = []
            @safe_predicates = []

            current_class_node = processed_source.ast&.each_node(:class)&.first
            parent_class_name = find_superclass_name(current_class_node)

            ce_class_name = extract_policy_name
            if ce_class_name
              path = resolve_parent_file_path(ce_class_name)
              load_parent_policy_aliases(path) if path
            end

            if parent_class_name
              path = resolve_parent_file_path(parent_class_name)
              load_parent_policy_aliases(path) if path
            end

            return unless processed_source.ast

            collect_aliases(processed_source.ast)
            check_conditions(processed_source.ast)
          end

          private

          def collect_aliases(ast)
            def_nodes = []

            ast.each_node do |node|
              case node.type
              when :def
                def_nodes << node
                process_def(node, @subject_aliases, @user_aliases, @safe_predicates)
              when :send
                process_alias_method(node, @subject_aliases, @user_aliases) if node.method?(:alias_method)
              end
            end

            # Second pass: resolve transitive aliases (methods that call known aliases)
            resolve_transitive_aliases(def_nodes)
          end

          def resolve_transitive_aliases(def_nodes)
            # Each iteration can resolve at most one new alias, so the maximum
            # number of productive iterations is bounded by def_nodes.size.
            # The safety limit guards against unforeseen edge cases.
            max_iterations = def_nodes.size + 1
            iteration = 0

            loop do
              iteration += 1
              break if iteration > max_iterations

              changed = false
              def_nodes.each { |node| changed |= try_resolve_transitive_alias(node) }
              break unless changed
            end
          end

          def try_resolve_transitive_alias(node)
            return false unless node.body

            method_name = node.method_name
            return false if @subject_aliases.include?(method_name) || @user_aliases.include?(method_name)

            calls = extract_unqualified_calls(node.body)
            refs_subject = calls.any? { |c| @subject_aliases.include?(c) || c == :subject }
            refs_user = calls.any? { |c| @user_aliases.include?(c) || c == :user }

            if refs_subject && !refs_user
              @subject_aliases << method_name
            elsif refs_user && !refs_subject
              @user_aliases << method_name
            else
              return false
            end

            true
          end

          def extract_unqualified_calls(body)
            [body, *body.each_descendant(:send)]
              .select { |n| n.send_type? && n.receiver.nil? }
              .map(&:method_name)
          end

          def check_conditions(ast)
            children = collect_top_level_children(ast)

            pending_scope = nil
            pending_scope_node = nil

            children.each do |node|
              case node.type
              when :send
                scope_value = with_scope_call?(node)
                if scope_value && VALID_SCOPES.include?(scope_value)
                  pending_scope = scope_value
                  pending_scope_node = node
                  next
                end

                scope_node, scope_value = with_options_scope(node)
                if scope_value && VALID_SCOPES.include?(scope_value)
                  pending_scope = scope_value
                  pending_scope_node = scope_node
                  next
                end

              when :block, :numblock
                send_node = node.send_node

                if send_node.method?(:condition)
                  # Inline scope takes precedence over pending with_scope/with_options
                  inline_scope_node, inline_scope = extract_inline_scope(send_node.arguments)

                  scope = inline_scope || pending_scope
                  offense_node = inline_scope_node || pending_scope_node

                  check_condition_block(node, scope, offense_node) if scope

                  pending_scope = nil
                  pending_scope_node = nil
                  next
                end
              end

              # Any non-with_scope/with_options/condition node resets pending scope
              pending_scope = nil
              pending_scope_node = nil
            end
          end

          def collect_top_level_children(ast)
            children = []

            # Handle top-level statements (bare conditions not inside class/module)
            if ast.begin_type?
              ast.children.each { |child| children << child }
            elsif !%i[class module sclass].include?(ast.type)
              children << ast
            end

            # Collect from class/module bodies
            ast.each_node(:class, :module, :sclass) do |container|
              collect_body_children(container.body, children)
            end

            # Collect from DSL blocks like `prepended do ... end`
            ast.each_node(:block, :numblock) do |block_node|
              next unless %i[prepended class_methods included].include?(block_node.method_name)

              collect_body_children(block_node.body, children)
            end

            children
          end

          def collect_body_children(body, children)
            return unless body

            if body.begin_type?
              body.children.each { |child| children << child }
            else
              children << body
            end
          end

          def extract_inline_scope(args)
            args.each do |arg|
              scope_node, scope_value = scope_from_hash_arg(arg)
              return [scope_node, scope_value] if scope_value
            end

            [nil, nil]
          end

          def check_condition_block(block_node, scope, offense_node)
            return unless VALID_SCOPES.include?(scope)

            used_references = extract_references(block_node)
            allowed_references = allowed_references_for(scope)
            disallowed = used_references - allowed_references

            return if disallowed.empty?

            add_offense(offense_node || block_node.send_node,
              message: format(MSG, scope: scope, cache_desc: SCOPE_CACHE_DESCRIPTION[scope],
                references: disallowed.join(', ')))
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

          def extract_references(block_node)
            return [] unless block_node.body

            ivars = block_node.each_descendant(:ivar).map { |n| n.children.first }
            method_calls = block_node.body.each_descendant(:send)
              .select { |n| n.receiver.nil? && n.arguments.empty? && !used_in_condition?(n) }
              .map(&:method_name)
              .reject { |name| @safe_predicates.include?(name) }

            (ivars + method_calls).uniq
          end

          def used_in_condition?(node)
            parent = node.parent
            return false unless parent

            %i[if elsif unless].include?(parent.type) && parent.condition == node
          end

          def boolean_literal?(body_node)
            %i[true false].include?(body_node.type)
          end

          # --- Alias resolution ---

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

          # --- Parent policy file resolution ---

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

            %w[app/policies ee/app/policies].each do |dir|
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

            @subject_aliases.uniq!
            @user_aliases.uniq!
            @safe_predicates.uniq!
          end

          def get_or_parse_policy_file(path)
            cache = self.class.parsed_files_cache
            return cache[path] if cache.key?(path)

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
          rescue Errno::ENOENT, Errno::EACCES
            nil
          end
        end
      end
    end
  end
end
