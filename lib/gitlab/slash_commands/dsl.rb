module Gitlab
  module SlashCommands
    module Dsl
      extend ActiveSupport::Concern

      included do
        @command_definitions = []
      end

      module ClassMethods
        def command_definitions
          @command_definitions
        end

        def command_names
          command_definitions.flat_map do |command_definition|
            unless command_definition[:noop]
              [command_definition[:name], command_definition[:aliases]].flatten
            end
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
            params: @params || [],
            noop: @noop || false
          }
          @command_definitions << command_definition

          @description = nil
          @params = nil
        end
      end
    end
  end
end
