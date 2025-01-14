# frozen_string_literal: true

module Gitlab
  module Regex
    module Packages
      module Protection
        module Rules
          def self.protection_rules_npm_package_name_pattern_regex
            @protection_rules_npm_package_name_pattern_regex ||= Gitlab::Regex.npm_package_name_regex('*')
          end

          def self.protection_rules_pypi_package_name_pattern_regex
            @protection_rules_pypi_package_name_pattern_regex ||= Gitlab::Regex.package_name_regex('*')
          end
        end
      end
    end
  end
end
