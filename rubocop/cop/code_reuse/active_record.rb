# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that blacklists the use of ActiveRecord methods outside of models.
      class ActiveRecord < RuboCop::Cop::Cop
        include CodeReuseHelpers

        MSG = 'This method can only be used inside an ActiveRecord model'

        # Various methods from ActiveRecord::Querying that are blacklisted. We
        # exclude some generic ones such as `any?` and `first`, as these may
        # lead to too many false positives, since `Array` also supports these
        # methods.
        #
        # The keys of this Hash are the blacklisted method names. The values are
        # booleans that indicate if the method should only be blacklisted if any
        # arguments are provided.
        NOT_ALLOWED = {
          average: true,
          calculate: true,
          count_by_sql: true,
          create_with: true,
          distinct: false,
          eager_load: true,
          except: true,
          exists?: true,
          find_by: true,
          find_by!: true,
          find_by_sql: true,
          find_each: true,
          find_in_batches: true,
          find_or_create_by: true,
          find_or_create_by!: true,
          find_or_initialize_by: true,
          first!: false,
          first_or_create: true,
          first_or_create!: true,
          first_or_initialize: true,
          from: true,
          group: true,
          having: true,
          ids: false,
          includes: true,
          joins: true,
          limit: true,
          lock: false,
          many?: false,
          none: false,
          offset: true,
          order: true,
          pluck: true,
          preload: true,
          readonly: false,
          references: true,
          reorder: true,
          rewhere: true,
          sum: false,
          take: false,
          take!: false,
          unscope: false,
          where: false,
          with: true
        }.freeze

        # Directories that allow the use of the blacklisted methods. These
        # directories are checked relative to both . and ee/
        WHITELISTED_DIRECTORIES = %w[
          app/models
          config
          danger
          db
          lib/backup
          lib/banzai
          lib/gitlab/background_migration
          lib/gitlab/cycle_analytics
          lib/gitlab/database
          lib/gitlab/import_export
          lib/gitlab/project_authorizations
          lib/gitlab/sql
          lib/system_check
          lib/tasks
          qa
          rubocop
          spec
        ].freeze

        def on_send(node)
          return if in_whitelisted_directory?(node)

          receiver = node.children[0]
          send_name = node.children[1]
          first_arg = node.children[2]

          if receiver && NOT_ALLOWED.key?(send_name)
            # If the rule requires an argument to be given, but none are
            # provided, we won't register an offense. This prevents us from
            # adding offenses for `project.group`, while still covering
            # `Project.group(:name)`.
            return if NOT_ALLOWED[send_name] && !first_arg

            add_offense(node, location: :selector)
          end
        end

        # Returns true if the node resides in one of the whitelisted
        # directories.
        def in_whitelisted_directory?(node)
          path = file_path_for_node(node)

          WHITELISTED_DIRECTORIES.any? do |directory|
            path.start_with?(
              File.join(rails_root, directory),
              File.join(rails_root, 'ee', directory)
            )
          end
        end

        # We can not auto correct code like this, as it requires manual
        # refactoring. Instead, we'll just whitelist the surrounding scope.
        #
        # Despite this method's presence, you should not use it. This method
        # exists to make it possible to whitelist large chunks of offenses we
        # can't fix in the short term. If you are writing new code, follow the
        # code reuse guidelines, instead of whitelisting any new offenses.
        def autocorrect(node)
          scope = surrounding_scope_of(node)
          indent = indentation_of(scope)

          lambda do |corrector|
            # This prevents us from inserting the same enable/disable comment
            # for a method or block that has multiple offenses.
            next if whitelisted_scopes.include?(scope)

            corrector.insert_before(
              scope.source_range,
              "# rubocop: disable #{cop_name}\n#{indent}"
            )

            corrector.insert_after(
              scope.source_range,
              "\n#{indent}# rubocop: enable #{cop_name}"
            )

            whitelisted_scopes << scope
          end
        end

        def indentation_of(node)
          ' ' * node.loc.expression.source_line[/\A */].length
        end

        def surrounding_scope_of(node)
          %i[def defs block begin].each do |type|
            if (found = node.each_ancestor(type).first)
              return found
            end
          end
        end

        def whitelisted_scopes
          @whitelisted_scopes ||= Set.new
        end
      end
    end
  end
end
