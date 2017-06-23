module Gitlab
  module SlashCommands
    module Dsl
      extend ActiveSupport::Concern

      included do
        cattr_accessor :command_definitions, instance_accessor: false do
          []
        end

        cattr_accessor :command_definitions_by_name, instance_accessor: false do
          {}
        end
      end

      class_methods do
        # Allows to give a description to the next slash command.
        # This description is shown in the autocomplete menu.
        # It accepts a block that will be evaluated with the context given to
        # `CommandDefintion#to_h`.
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
        def params(*params, &block)
          @params = block_given? ? block : params
        end

        # Allows to give an explanation of what the command will do when
        # executed. This explanation is shown when rendering the Markdown
        # preview.
        #
        # Example:
        #
        #   explanation do |arguments|
        #     "Adds label(s) #{arguments.join(' ')}"
        #   end
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        def explanation(text = '', &block)
          @explanation = block_given? ? block : text
        end

        # Allows to define conditions that must be met in order for the command
        # to be returned by `.command_names` & `.command_definitions`.
        # It accepts a block that will be evaluated with the context given to
        # `CommandDefintion#to_h`.
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

        # Allows to perform initial parsing of parameters. The result is passed
        # both to `command` and `explanation` blocks, instead of the raw
        # parameters.
        # It accepts a block that will be evaluated with the context given to
        # `CommandDefintion#to_h`.
        #
        # Example:
        #
        #   parse_params do |raw|
        #     raw.strip
        #   end
        #   command :command_key do |parsed|
        #     # Awesome code block
        #   end
        def parse_params(&block)
          @parse_params_block = block
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
          name, *aliases = command_names

          definition = CommandDefinition.new(
            name,
            aliases: aliases,
            description: @description,
            explanation: @explanation,
            params: @params,
            condition_block: @condition_block,
            parse_params_block: @parse_params_block,
            action_block: block
          )

          self.command_definitions << definition

          definition.all_names.each do |name|
            self.command_definitions_by_name[name] = definition
          end

          @description = nil
          @explanation = nil
          @params = nil
          @condition_block = nil
          @parse_params_block = nil
        end

        def definition_by_name(name)
          command_definitions_by_name[name.to_sym]
        end
      end
    end
  end
end
