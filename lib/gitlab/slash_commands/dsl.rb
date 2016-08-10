module Gitlab
  module SlashCommands
    module Dsl
      extend ActiveSupport::Concern

      included do
        @command_definitions = []
      end

      module ClassMethods
        def command_definitions(opts = {})
          @command_definitions.map do |cmd_def|
            next if cmd_def[:cond_lambda] && !cmd_def[:cond_lambda].call(opts)

            cmd_def = cmd_def.dup

            if cmd_def[:description].present? && cmd_def[:description].respond_to?(:call)
              cmd_def[:description] = cmd_def[:description].call(opts) rescue ''
            end

            cmd_def
          end.compact
        end

        def command_names(opts = {})
          command_definitions(opts).flat_map do |command_definition|
            next if command_definition[:noop]

            [command_definition[:name], *command_definition[:aliases]]
          end.compact
        end

        # Allows to give a description to the next slash command
        def desc(text)
          @description = text
        end

        # Allows to define params for the next slash command
        def params(*params)
          @params = params
        end

        # Allows to define if a command is a no-op, but should appear in autocomplete
        def noop(noop)
          @noop = noop
        end

        # Allows to define if a lambda to conditionally return an action
        def condition(cond_lambda)
          @cond_lambda = cond_lambda
        end

        # Registers a new command which is recognizeable
        # from body of email or comment.
        # Example:
        #
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        #
        def command(*command_names, &block)
          command_name, *aliases = command_names
          proxy_method_name = "__#{command_name}__"

          # This proxy method is needed because calling `return` from inside a
          # block/proc, causes a `return` from the enclosing method or lambda,
          # otherwise a LocalJumpError error is raised.
          define_method(proxy_method_name, &block)

          define_method(command_name) do |*args|
            unless @cond_lambda.nil? || @cond_lambda.call(project: project, current_user: current_user, noteable: noteable)
              return
            end

            proxy_method = method(proxy_method_name)

            if proxy_method.arity == -1 || proxy_method.arity == args.size
              instance_exec(*args, &proxy_method)
            end
          end

          private command_name
          aliases.each do |alias_command|
            alias_method alias_command, command_name
            private alias_command
          end

          command_definition = {
            name: command_name,
            aliases: aliases,
            description: @description || '',
            params: @params || []
          }
          command_definition[:noop] = @noop unless @noop.nil?
          command_definition[:cond_lambda] = @cond_lambda unless @cond_lambda.nil?
          @command_definitions << command_definition

          @description = nil
          @params = nil
          @noop = nil
          @cond_lambda = nil
        end
      end
    end
  end
end
