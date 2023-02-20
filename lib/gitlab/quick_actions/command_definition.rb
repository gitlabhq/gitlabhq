# frozen_string_literal: true

module Gitlab
  module QuickActions
    class CommandDefinition
      ParseError = Class.new(StandardError)

      attr_accessor :name, :aliases, :description, :explanation, :execution_message,
        :params, :condition_block, :parse_params_block, :action_block, :warning, :icon, :types

      def initialize(name, attributes = {})
        @name = name

        @aliases = attributes[:aliases] || []
        @description = attributes[:description] || ''
        @warning = attributes[:warning] || ''
        @icon = attributes[:icon] || ''
        @explanation = attributes[:explanation] || ''
        @execution_message = attributes[:execution_message] || ''
        @params = attributes[:params] || []
        @condition_block = attributes[:condition_block]
        @parse_params_block = attributes[:parse_params_block]
        @action_block = attributes[:action_block]
        @types = attributes[:types] || []
      end

      def all_names
        [name, *aliases]
      end

      def noop?
        action_block.nil?
      end

      def available?(context)
        return false unless valid_type?(context)
        return true unless condition_block

        context.instance_exec(&condition_block)
      end

      def explain(context, arg)
        return unless available?(context)

        message = if explanation.respond_to?(:call)
                    begin
                      execute_block(explanation, context, arg)
                    rescue ParseError => e
                      format(_('Problem with %{name} command: %{message}.'), name: name, message: e.message)
                    end
                  else
                    explanation
                  end

        warning_text = if warning.respond_to?(:call)
                         execute_block(warning, context, arg)
                       else
                         warning
                       end

        warning.empty? ? message : "#{message} (#{warning_text})"
      end

      def execute(context, arg)
        return if noop?

        count_commands_executed_in(context)

        return unless available?(context)

        execute_block(action_block, context, arg)
      rescue ParseError
        # message propagation is handled in `execution_message`.
      end

      def execute_message(context, arg)
        return if noop?
        return _('Could not apply %{name} command.') % { name: name } unless available?(context)

        if execution_message.respond_to?(:call)
          execute_block(execution_message, context, arg)
        else
          execution_message
        end
      rescue ParseError => e
        format _('Could not apply %{name} command. %{message}.'), name: name, message: e.message
      end

      def to_h(context)
        desc = description
        if desc.respond_to?(:call)
          desc = begin
            context.instance_exec(&desc)
          rescue StandardError
            ''
          end
        end

        warn = warning
        if warn.respond_to?(:call)
          warn = begin
            context.instance_exec(&warn)
          rescue StandardError
            ''
          end
        end

        prms = params
        if prms.respond_to?(:call)
          prms = begin
            Array(context.instance_exec(&prms))
          rescue StandardError
            params
          end
        end

        {
          name: name,
          aliases: aliases,
          description: desc,
          warning: warn,
          icon: icon,
          params: prms
        }
      end

      private

      def count_commands_executed_in(context)
        return unless context.respond_to?(:commands_executed_count=)

        context.commands_executed_count ||= 0
        context.commands_executed_count += 1
      end

      def execute_block(block, context, arg)
        if arg.present?
          parsed = parse_params(arg, context)
          context.instance_exec(parsed, &block)
        elsif block.arity == 0
          context.instance_exec(&block)
        end
      end

      def parse_params(arg, context)
        return arg unless parse_params_block

        context.instance_exec(arg, &parse_params_block)
      end

      def valid_type?(context)
        types.blank? || types.any? do |type|
          if context.quick_action_target.is_a?(WorkItem)
            context.quick_action_target.supported_quick_action_commands.include?(name.to_sym)
          else
            context.quick_action_target.is_a?(type)
          end
        end
      end
    end
  end
end
