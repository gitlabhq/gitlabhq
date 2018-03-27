module Gitlab
  module QuickActions
    class SubstitutionDefinition < CommandDefinition
      # noop?=>true means these won't get extracted or removed by Gitlab::QuickActions::Extractor#extract_commands
      # QuickActions::InterpretService#perform_substitutions handles them separately
      def noop?
        true
      end

      def match(content)
        content.match %r{^/#{all_names.join('|')} ?(.*)$}
      end

      def perform_substitution(context, content)
        return unless content

        all_names.each do |a_name|
          content.gsub!(%r{/#{a_name} ?(.*)$}, execute_block(action_block, context, '\1'))
        end
        content
      end
    end
  end
end
