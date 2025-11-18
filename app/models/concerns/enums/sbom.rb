# frozen_string_literal: true

module Enums
  class Sbom
    COMPONENT_TYPES = {
      library: 0
    }.with_indifferent_access.freeze

    PURL_TYPES = {
      not_provided: 0,
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
      conda: 16,
      pub: 17,
      unknown: 999
    }.with_indifferent_access.freeze

    # INTERNAL_PURL_TYPES are purl types that are used by GitLab internally for
    # features. These types are not officially recognized, or even proposed, nor
    # should they. For example, 'unknown' is the PURL type used to describe components
    # for which we have no knowledge, and `'not_provided' is used for components`
    # for which did not provide a PURL type. Outside of GitLab these are not usable,
    # and should not be surfaced to customers outside of very specific contexts.
    # A concrete example is the dependency list where customers would like to see
    # components that have no PURL type, or have a PURL type that's not handled.
    # In other contexts like in the Package Metadata Database admin configuration
    # page, these don't make sense, so it's best to exclude (customers can't sync data
    # for 'unknown' or 'not_provided' packages).
    INTERNAL_PURL_TYPES = %w[unknown not_provided].freeze

    UNKNOWN = :unknown
    IN_USE = :in_use
    NOT_FOUND = :not_found

    REACHABILITY_TYPES = {
      UNKNOWN => 0, # reachability analysis was not available for this component
      # (this attribute can't be renamed as it would be a breaking change)
      IN_USE => 1, # component is known to be in use
      NOT_FOUND => 2 # component was not found to be in use
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
      pub
    ].freeze

    CONTAINER_SCANNING_PURL_TYPES = %w[
      apk
      rpm
      deb
      cbl-mariner
      wolfi
    ].freeze

    # Package types supported by Trivy are sourced from
    # https://github.com/aquasecurity/trivy/blob/8e6a7ff670c64106d4dea6972ac3f6228f9c6269/pkg/fanal/analyzer/const.go
    PACKAGE_MANAGERS_FROM_TRIVY_PKG_TYPE = {
      # OS
      alma: 'dnf',
      alpine: 'apk',
      amazon: 'yum',
      azurelinux: 'tdnf',
      bottlerocket: 'bottlerocket',
      'cbl-mariner': 'tdnf',
      centos: 'dnf',
      chainguard: 'apk',
      coreos: 'dnf',
      debian: 'apt',
      echo: 'apt',
      fedora: 'dnf',
      minimos: 'apt',
      opensuse: 'zypper',
      'opensuse-leap': 'zypper',
      'opensuse-tumbleweed': 'zypper',
      oracle: 'dnf',
      photon: 'tdnf',
      redhat: 'dnf',
      rocky: 'dnf',
      slem: 'zypper',
      sles: 'zypper',
      ubuntu: 'apt',
      wolfi: 'apk',

      # Application package types
      bundler: 'bundler',
      gemspec: 'bundler',
      cargo: 'cargo',
      composer: 'composer',
      'composer-vendor': 'composer',
      npm: 'npm',
      bun: 'bun',
      nuget: 'nuget',
      'dotnet-core': 'nuget',
      'packages-props': 'nuget',
      pip: 'pip',
      pipenv: 'pipenv',
      poetry: 'poetry',
      uv: 'uv',
      'conda-pkg': 'conda',
      'conda-environment': 'conda',
      'python-pkg': 'pip',
      'node-pkg': 'npm',
      yarn: 'yarn',
      pnpm: 'pnpm',
      jar: 'maven',
      pom: 'maven',
      gradle: 'gradle',
      sbt: 'sbt',
      gobinary: 'go',
      gomod: 'go',
      javascript: 'npm',
      rustbinary: 'cargo',
      conan: 'conan',
      cocoapods: 'cocoapods',
      swift: 'cocoapods',
      pub: 'pub',
      hex: 'hex',
      bitnami: 'bitnami',
      julia: 'julia',

      #######################################
      # Historical Trivy mappings
      # Keep for backward compatibility
      #######################################

      # OS
      suse: 'zypper',
      'ubuntu-esm': 'apt',

      # OS package types
      apk: 'apk',
      dpkg: 'apt',
      'dpkg-license': 'apt',
      rpm: 'dnf',
      rpmqa: 'dnf',

      # Application package types
      'gradle-lockfile': 'gradle',
      'sbt-lockfile': 'sbt',
      'python-egg': 'pip',
      'conan-lock': 'conan',
      'mix-lock': 'mix',
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
      # if PURL is empty or nil then mark it as not_provided,
      # othewise mark it as unsupported
      @_purl_types ||= PURL_TYPES.dup.tap do |h|
        h.default_proc = proc { |_, key| key.to_s.blank? ? 0 : 999 }
      end
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
