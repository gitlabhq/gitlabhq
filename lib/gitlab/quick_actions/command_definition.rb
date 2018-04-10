module Gitlab
  module QuickActions
    class CommandDefinition
      attr_accessor :name, :aliases, :description, :explanation, :params,
        :condition_block, :parse_params_block, :action_block

      def initialize(name, attributes = {})
        @name = name

        @aliases = attributes[:aliases] || []
        @description = attributes[:description] || ''
        @explanation = attributes[:explanation] || ''
        @params = attributes[:params] || []
        @condition_block = attributes[:condition_block]
        @parse_params_block = attributes[:parse_params_block]
        @action_block = attributes[:action_block]
      end

      def all_names
        [name, *aliases]
      end

      def noop?
        action_block.nil?
      end

      def available?(context)
        return true unless condition_block

        context.instance_exec(&condition_block)
      end

      def explain(context, arg)
        return unless available?(context)

        if explanation.respond_to?(:call)
          execute_block(explanation, context, arg)
        else
          explanation
        end
      end

      def execute(context, arg)
        return if noop? || !available?(context)

        execute_block(action_block, context, arg)
      end

      def to_h(context)
        desc = description
        if desc.respond_to?(:call)
          desc = context.instance_exec(&desc) rescue ''
        end

        prms = params
        if prms.respond_to?(:call)
          prms = Array(context.instance_exec(&prms)) rescue params
        end

        {
          name: name,
          aliases: aliases,
          description: desc,
          params: prms
        }
      end

      private

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
    end
  end
end
