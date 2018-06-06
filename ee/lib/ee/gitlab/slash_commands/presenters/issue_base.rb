module EE
  module Gitlab
    module SlashCommands
      module Presenters
        module IssueBase
          extend ::Gitlab::Utils::Override

          override :fields
          def fields
            super.concat(
              [
                {
                  title: "Weight",
                  value: resource.weight? ? resource.weight : "_None_",
                  short: true
                }
              ]
            )
          end
        end
      end
    end
  end
end
