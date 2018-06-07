module EE
  module Gitlab
    module SlashCommands
      module Command
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override
          override :commands

          def commands
            super.concat(
              [
                ::Gitlab::SlashCommands::Run
              ]
            )
          end
        end
      end
    end
  end
end
