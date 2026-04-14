# frozen_string_literal: true

module Gitlab
  module Regex
    module Packages
      module Protection
        module Rules
          # Regex for NPM package name patterns in protection rules.
          # Accepts package names with optional wildcards, including standalone '*' to match all packages.
          #
          # Examples:
          #   - '*' (matches all packages)
          #   - '@scope/package-*' (matches packages with wildcard at end)
          #   - '@scope/*-package' (matches packages with wildcard at start)
          def self.protection_rules_npm_package_name_pattern_regex
            @protection_rules_npm_package_name_pattern_regex ||=
              %r{\A(?:\*|#{Gitlab::Regex.npm_package_name_regex('*')})\z}
          end

          # Regex for PyPI package name patterns in protection rules.
          # Accepts package names with optional wildcards, including standalone '*' to match all packages.
          #
          # Examples:
          #   - '*' (matches all packages)
          #   - 'package-*' (matches packages with wildcard at end)
          #   - '*-package' (matches packages with wildcard at start)
          def self.protection_rules_pypi_package_name_pattern_regex
            @protection_rules_pypi_package_name_pattern_regex ||=
              %r{\A(?:\*|#{Gitlab::Regex.package_name_regex('*')})\z}
          end

          # Regex for Terraform module package name patterns in protection rules.
          # Accepts names in `module_name/module_system` format with optional wildcards.
          #
          # Examples:
          #   - '*' (matches all packages)
          #   - 'my-module/aws*' (matches with wildcard at end)
          #   - '*/aws' (matches any module name with system 'aws')
          def self.protection_rules_terraform_module_package_name_pattern_regex
            @protection_rules_terraform_module_package_name_pattern_regex ||=
              %r{\A(?:\*|[-a-z0-9*]+/[-a-z0-9*]+)\z}
          end
        end
      end
    end
  end
end
