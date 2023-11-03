# frozen_string_literal: true

module Gitlab
  module Regex
    module Packages
      module Protection
        module Rules
          def protection_rules_npm_package_name_pattern_regex
            @protection_rules_npm_package_name_pattern_regex ||= npm_package_name_regex('*')
          end
        end
      end
    end
  end
end
