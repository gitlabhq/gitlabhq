# frozen_string_literal: true

require 'rubocop'

module Keeps
  module OverdueFinalizeBackgroundMigrations
    # Rewrites a generated post-deployment migration so its `up` method finalizes the batched background
    # migration originally queued in `queue_migration_file`, resolving any constants the queue call
    # references to their literal source.
    class MigrationRewriter
      RUBY_VERSION_FOR_PARSING = 3.1

      def find_queue_method_node(file)
        migration_ast = parse(file).ast

        find_up_method(migration_ast).each_descendant.find do |child|
          child.send_type? && child.method_name == :queue_batched_background_migration
        end
      end

      def add_ensure_call_to_migration(file, queue_method_node, job_name, migration_record)
        source = parse(file)
        rewriter = Parser::Source::TreeRewriter.new(source.buffer)
        up_method = find_up_method(source.ast)

        rewriter.replace(up_method.loc.expression, ensure_call_source(queue_method_node, job_name, migration_record))

        File.write(file, strip_comments(rewriter.process))
      end

      private

      def parse(file)
        RuboCop::ProcessedSource.new(File.read(file), RUBY_VERSION_FOR_PARSING)
      end

      def find_up_method(ast)
        ast.children[2].each_child_node(:def).find { |child| child.method_name == :up }
      end

      def ensure_call_source(queue_method_node, job_name, migration_record)
        constants = constant_assignments(queue_method_node)

        table_name = resolve_node_source(queue_method_node.children[3], constants)
        column_name = resolve_node_source(queue_method_node.children[4], constants)
        job_arguments = queue_method_node.children[5..]
          .select { |s| s.type != :hash } # All remaining non-keyword args
          .map { |arg| resolve_node_source(arg, constants) }

        <<~RUBY.strip
        disable_ddl_transaction!

        restrict_gitlab_migration gitlab_schema: :#{migration_record.gitlab_schema}

          def up
            ensure_batched_background_migration_is_finished(
              job_class_name: '#{job_name}',
              table_name: #{table_name},
              column_name: #{column_name},
              job_arguments: [#{job_arguments.join(', ')}],
              finalize: true
            )
          end
        RUBY
      end

      # Collects top-level constants (e.g. MIGRATION, BATCH_SIZE) defined in the original migration class,
      # since they aren't available in the generated finalize migration and must be inlined.
      def constant_assignments(queue_method_node)
        class_node = queue_method_node.each_ancestor(:class, :module).first
        return {} unless class_node

        class_node.each_descendant(:casgn).each_with_object({}) do |casgn, assignments|
          namespace, const_name, value_node = casgn.children
          assignments[const_name] = value_node if namespace.nil? && value_node
        end
      end

      # Replaces bare top-level constant references in the node with their literal source, recursing into
      # composite expressions (e.g. array literals). Only unqualified constants are rewritten so `Foo::BAR`
      # is left intact; `seen` breaks self-referential cycles.
      def resolve_node_source(node, constants, seen = [])
        replaceable = node.each_node(:const).select do |const|
          namespace, const_name = const.children
          namespace.nil? && constants.key?(const_name) && seen.exclude?(const_name) && !const.parent&.const_type?
        end
        return node.source if replaceable.empty?

        rewriter = Parser::Source::TreeRewriter.new(node.loc.expression.source_buffer)
        replacements = replaceable.index_with { |const| resolve_constant_source(const.children[1], constants, seen) }
        replacements.each { |const, text| rewriter.replace(const.loc.expression, text) }

        # Slice the rewritten node out of the buffer: its start plus the net length change from replacements.
        range = node.loc.expression
        delta = replacements.sum { |const, text| text.length - const.source.length }
        rewriter.process[range.begin_pos, range.length + delta]
      end

      # Resolves a constant to its literal, following constant-to-constant chains and inlining constants
      # nested in composite values. Cycles fall back to raw source.
      def resolve_constant_source(const_name, constants, seen = [])
        value_node = constants[const_name]
        return const_name.to_s unless value_node

        resolve_node_source(value_node, constants, seen + [const_name])
      end

      def strip_comments(code)
        result = []
        code.each_line.with_index do |line, index|
          result << line unless index > 0 && line.lstrip.start_with?('#')
        end
        result.join
      end
    end
  end
end
