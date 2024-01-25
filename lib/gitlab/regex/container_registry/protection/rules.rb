# frozen_string_literal: true

module Gitlab
  module Regex
    module ContainerRegistry
      module Protection
        module Rules
          def self.protection_rules_container_repository_path_pattern_regex
            @protection_rules_container_repository_path_pattern_regex ||=
              Gitlab::Regex.container_repository_name_regex('*')
          end
        end
      end
    end
  end
end
