# frozen_string_literal: true

module Enums
  class Sbom
    COMPONENT_TYPES = {
      library: 0
    }.with_indifferent_access.freeze

    PURL_TYPES = {
      composer: 1, # refered to as `packagist` in gemnasium-db and semver_dialects
      conan: 2,
      gem: 3,
      golang: 4, # refered to as `go` in gemnasium-db and semver_dialects
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8,
      apk: 9,
      rpm: 10,
      deb: 11,
      'cbl-mariner': 12,
      wolfi: 13,
      cargo: 14,
      swift: 15,
      conda: 16
    }.with_indifferent_access.freeze

    REACHABILITY_TYPES = {
      unknown: 0,
      in_use: 1 # In case package imported and being used in code.
    }.with_indifferent_access.freeze

    DEPENDENCY_SCANNING_PURL_TYPES = %w[
      composer
      conan
      gem
      golang
      maven
      npm
      nuget
      pypi
      cargo
      swift
      conda
    ].freeze

    CONTAINER_SCANNING_PURL_TYPES = %w[
      apk
      rpm
      deb
      cbl-mariner
      wolfi
    ].freeze

    # Package types supported by Trivy are sourced from
    # https://github.com/aquasecurity/trivy/blob/214546427e76da21bbc61a5b70ec00d5b95f6d0b/pkg/sbom/cyclonedx/marshal.go#L21
    PACKAGE_MANAGERS_FROM_TRIVY_PKG_TYPE = {
      # OS
      alpine: 'apk',
      amazon: 'yum',
      'cbl-mariner': 'tdnf',
      debian: 'apt',
      photon: 'tdnf',
      centos: 'dnf',
      rocky: 'dnf',
      alma: 'dnf',
      fedora: 'dnf',
      oracle: 'dnf',
      redhat: 'dnf',
      suse: 'zypper',
      ubuntu: 'apt',
      'ubuntu-esm': 'apt',

      # OS package types
      apk: 'apk',
      dpkg: 'apt',
      'dpkg-license': 'apt',
      rpm: 'dnf',
      rpmqa: 'dnf',

      # Application package types
      bundler: 'bundler',
      gemspec: 'bundler',
      rustbinary: 'cargo',
      cargo: 'cargo',
      composer: 'composer',
      jar: 'maven',
      pom: 'maven',
      'gradle-lockfile': 'gradle',
      npm: 'npm',
      'node-pkg': 'npm',
      yarn: 'yarn',
      pnpm: 'pnpm',
      nuget: 'nuget',
      'dotnet-core': 'nuget',
      'conda-pkg': 'conda',
      'conda-environment': 'conda',
      'python-pkg': 'pip',
      pip: 'pip',
      pipenv: 'pipenv',
      poetry: 'poetry',
      gobinary: 'go',
      gomod: 'go',
      'conan-lock': 'conan',
      'mix-lock': 'mix',
      swift: 'cocoapods',
      cocoapods: 'cocoapods',
      'pubspec-lock': 'pub'
    }.with_indifferent_access.freeze

    def self.component_types
      COMPONENT_TYPES
    end

    def self.dependency_scanning_purl_type?(purl_type)
      DEPENDENCY_SCANNING_PURL_TYPES.include?(purl_type)
    end

    def self.container_scanning_purl_type?(purl_type)
      CONTAINER_SCANNING_PURL_TYPES.include?(purl_type)
    end

    def self.purl_types
      # return 0 by default if the purl_type is not found, to prevent
      # consumers from producing invalid SQL caused by null entries
      @_purl_types ||= PURL_TYPES.dup.tap { |h| h.default = 0 }
    end

    def self.purl_types_numerical
      purl_types.invert
    end

    def self.reachability_types
      REACHABILITY_TYPES
    end

    def self.package_manager_from_trivy_pkg_type(pkg_type)
      PACKAGE_MANAGERS_FROM_TRIVY_PKG_TYPE[pkg_type]
    end

    # We do not use the namespaced names for OS component types even
    # if the PURL specification declares otherwise, since this will
    # preserve the name format established by the container-scanning
    # analyzers. For example, a namespaced name for an Alpine cURL component
    # might look like `apk/curl` when found by an SBOM generator. If found
    # by a container-scanning analyzer, this same component would be reported
    # as `curl`. The differences in naming would impact dependency and
    # vulnerability deduplication, and if left as is would create dependency
    # lists and vulnerability reports that are inaccurate.
    #
    # For full details, see https://gitlab.com/gitlab-org/gitlab/-/issues/442847
    def self.use_namespaced_name?(purl_type)
      case purl_type
      when 'apk', 'deb', 'rpm'
        false
      else
        true
      end
    end
  end
end
