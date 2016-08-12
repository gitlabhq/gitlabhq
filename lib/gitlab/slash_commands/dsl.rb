module Gitlab
  module SlashCommands
    module Dsl
      extend ActiveSupport::Concern

      included do
        cattr_accessor :definitions
      end

      def execute_command(name, *args)
        name = name.to_sym
        cmd_def = self.class.definitions.find do |cmd_def|
          self.class.command_name_and_aliases(cmd_def).include?(name)
        end
        return unless cmd_def && cmd_def[:action_block]
        return if self.class.command_unavailable?(cmd_def, self)

        block_arity = cmd_def[:action_block].arity
        if block_arity == -1 || block_arity == args.size
          instance_exec(*args, &cmd_def[:action_block])
        end
      end

      class_methods do
        # This method is used to generate the autocompletion menu.
        # It returns no-op slash commands (such as `/cc`).
        def command_definitions(opts = {})
          self.definitions.map do |cmd_def|
            context = OpenStruct.new(opts)
            next if command_unavailable?(cmd_def, context)

            cmd_def = cmd_def.dup

            if cmd_def[:description].respond_to?(:call)
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
          self.definitions.flat_map do |cmd_def|
            next if cmd_def[:opts].fetch(:noop, false)

            context = OpenStruct.new(opts)
            next if command_unavailable?(cmd_def, context)

            command_name_and_aliases(cmd_def)
          end.compact
        end

        def command_unavailable?(cmd_def, context)
          cmd_def[:condition_block] && !context.instance_exec(&cmd_def[:condition_block])
        end

        def command_name_and_aliases(cmd_def)
          [cmd_def[:name], *cmd_def[:aliases]]
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
          @condition_block = block
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
          name, *aliases = command_names

          self.definitions ||= []
          self.definitions << {
            name: name,
            aliases: aliases,
            description: @description || '',
            params: @params || [],
            condition_block: @condition_block,
            action_block: block,
            opts: opts
          }

          @description = nil
          @params = nil
          @condition_block = nil
        end
      end
    end
  end
end
