module Gitlab
  module SlashCommands
    class CommandDefinition
      attr_accessor :name, :aliases, :description, :params, :condition_block, :action_block

      def initialize(name, attributes = {})
        @name = name

        @aliases         = attributes[:aliases] || []
        @description     = attributes[:description] || ''
        @params          = attributes[:params] || []
        @condition_block = attributes[:condition_block]
        @action_block    = attributes[:action_block]
      end

      def all_names
        [name, *aliases]
      end

      def noop?
        action_block.nil?
      end

      def available?(opts)
        return true unless condition_block

        context = OpenStruct.new(opts)
        context.instance_exec(&condition_block)
      end

      def execute(context, opts, args)
        return if noop? || !available?(opts)

        block_arity = action_block.arity
        return unless (args.present? && block_arity == 1) || (args.blank? && block_arity <= 0)

        context.instance_exec(args, &action_block)
      end

      def to_h(opts)
        desc = description
        if desc.respond_to?(:call)
          context = OpenStruct.new(opts)
          desc = context.instance_exec(&desc) rescue ''
        end

        {
          name: name,
          aliases: aliases,
          description: desc,
          params: params
        }
      end
    end
  end
end
