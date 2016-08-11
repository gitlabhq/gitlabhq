module Gitlab
  module SlashCommands
    module Dsl
      extend ActiveSupport::Concern

      included do
        @command_definitions = []
      end

      module ClassMethods
        # This method is used to generate the autocompletion menu
        # It returns no-op slash commands (such as `/cc`)
        def command_definitions(opts = {})
          @command_definitions.map do |cmd_def|
            context = OpenStruct.new(opts)
            next if cmd_def[:cond_block] && !context.instance_exec(&cmd_def[:cond_block])

            cmd_def = cmd_def.dup

            if cmd_def[:description].present? && cmd_def[:description].respond_to?(:call)
              cmd_def[:description] = context.instance_exec(&cmd_def[:description]) rescue ''
            end

            cmd_def
          end.compact
        end

        # This method is used to generate a list of valid commands in the current
        # context of `opts`.
        # It excludes no-op slash commands (such as `/cc`).
        # This list can then be given to `Gitlab::SlashCommands::Extractor`.
        def command_names(opts = {})
          command_definitions(opts).flat_map do |command_definition|
            next if command_definition[:noop]

            [command_definition[:name], *command_definition[:aliases]]
          end.compact
        end

        # Allows to give a description to the next slash command.
        # This description is shown in the autocomplete menu.
        # It accepts a block that will be evaluated with the context given to
        # `.command_definitions` or `.command_names`.
        #
        # Example:
        #
        #   desc do
        #     "This is a dynamic description for #{noteable.to_ability_name}"
        #   end
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        def desc(text = '', &block)
          @description = block_given? ? block : text
        end

        # Allows to define params for the next slash command.
        # These params are shown in the autocomplete menu.
        #
        # Example:
        #
        #   params "~label ~label2"
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        def params(*params)
          @params = params
        end

        # Allows to define conditions that must be met in order for the command
        # to be returned by `.command_names` & `.command_definitions`.
        # It accepts a block that will be evaluated with the context given to
        # `.command_definitions`, `.command_names`, and the actual command method.
        #
        # Example:
        #
        #   condition do
        #     project.public?
        #   end
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        def condition(&block)
          @cond_block = block
        end

        # Registers a new command which is recognizeable from body of email or
        # comment.
        # It accepts aliases and takes a block.
        #
        # Example:
        #
        #   command :my_command, :alias_for_my_command do |arguments|
        #     # Awesome code block
        #   end
        def command(*command_names, &block)
          opts = command_names.extract_options!
          command_name, *aliases = command_names
          proxy_method_name = "__#{command_name}__"

          if block_given?
            # This proxy method is needed because calling `return` from inside a
            # block/proc, causes a `return` from the enclosing method or lambda,
            # otherwise a LocalJumpError error is raised.
            define_method(proxy_method_name, &block)

            define_method(command_name) do |*args|
              return if @cond_block && !instance_exec(&@cond_block)

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
          end

          command_definition = {
            name: command_name,
            aliases: aliases,
            description: @description || '',
            params: @params || []
          }
          command_definition[:noop] = opts[:noop] || false
          command_definition[:cond_block] = @cond_block
          @command_definitions << command_definition

          @description = nil
          @params = nil
          @cond_block = nil
        end
      end
    end
  end
end
