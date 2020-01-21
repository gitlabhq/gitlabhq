# frozen_string_literal: true

module Gitlab
  module QuickActions
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
        # Allows to give a description to the next quick action.
        # This description is shown in the autocomplete menu.
        # It accepts a block that will be evaluated with the context given to
        # `CommandDefintion#to_h`.
        #
        # Example:
        #
        #   desc do
        #     "This is a dynamic description for #{quick_action_target.to_ability_name}"
        #   end
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        def desc(text = '', &block)
          @description = block_given? ? block : text
        end

        def warning(text = '', &block)
          @warning = block_given? ? block : text
        end

        def icon(string = '')
          @icon = string
        end

        # Allows to define params for the next quick action.
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

        # Allows to provide a message about quick action execution result, success or failure.
        # This message is shown after quick action execution and after saving the note.
        #
        # Example:
        #
        #   execution_message do |arguments|
        #     "Added label(s) #{arguments.join(' ')}"
        #   end
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        #
        # Note: The execution_message won't be executed unless the condition block returns true.
        #       execution_message block is executed always after the command block has run,
        #       for this reason if the condition block doesn't return true after the command block has
        #       run you need to set the @execution_message variable inside the command block instead as
        #       shown in the following example.
        #
        # Example using instance variable:
        #
        #   command :command_key do |arguments|
        #     # Awesome code block
        #     @execution_message[:command_key] = 'command_key executed successfully'
        #   end
        #
        def execution_message(text = '', &block)
          @execution_message = block_given? ? block : text
        end

        # Allows to define type(s) that must be met in order for the command
        # to be returned by `.command_names` & `.command_definitions`.
        #
        # It is being evaluated before the conditions block is being evaluated
        #
        # If no types are passed then any type is allowed as the check is simply skipped.
        #
        # Example:
        #
        #   types Commit, Issue, MergeRequest
        #   command :command_key do |arguments|
        #     # Awesome code block
        #   end
        def types(*types_list)
          @types = types_list
        end

        # Allows to define conditions that must be met in order for the command
        # to be returned by `.command_names` & `.command_definitions`.
        # It accepts a block that will be evaluated with the context
        # of a QuickActions::InterpretService instance
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
        # You can also set the @execution_message instance variable, on conflicts with
        # execution_message method the instance variable has precedence.
        #
        # Example:
        #
        #   command :my_command, :alias_for_my_command do |arguments|
        #     # Awesome code block
        #     @updates[:my_command] = 'foo'
        #
        #     @execution_message[:my_command] = 'my_command executed successfully'
        #   end
        def command(*command_names, &block)
          define_command(CommandDefinition, *command_names, &block)
        end

        # Registers a new substitution which is recognizable from body of email or
        # comment.
        # It accepts aliases and takes a block with the formatted content.
        #
        # Example:
        #
        #   command :my_substitution, :alias_for_my_substitution do |text|
        #     "#{text} MY AWESOME SUBSTITUTION"
        #   end
        def substitution(*substitution_names, &block)
          define_command(SubstitutionDefinition, *substitution_names, &block)
        end

        def definition_by_name(name)
          command_definitions_by_name[name.to_sym]
        end

        private

        def define_command(klass, *command_names, &block)
          name, *aliases = command_names

          definition = klass.new(
            name,
            aliases: aliases,
            description: @description,
            warning: @warning,
            icon: @icon,
            explanation: @explanation,
            execution_message: @execution_message,
            params: @params,
            condition_block: @condition_block,
            parse_params_block: @parse_params_block,
            action_block: block,
            types: @types
          )

          self.command_definitions << definition

          definition.all_names.each do |name|
            self.command_definitions_by_name[name] = definition
          end

          @description = nil
          @explanation = nil
          @execution_message = nil
          @params = nil
          @condition_block = nil
          @warning = nil
          @icon = nil
          @parse_params_block = nil
          @types = nil
        end
      end
    end
  end
end
