# frozen_string_literal: true

module Enums
  module Ci
    module JobArtifact
      NON_ERASABLE_FILE_TYPES = %w[trace].freeze

      REPORT_FILE_TYPES = {
        sast: %w[sast],
        secret_detection: %w[secret_detection],
        test: %w[junit],
        accessibility: %w[accessibility],
        coverage: %w[cobertura jacoco],
        codequality: %w[codequality],
        terraform: %w[terraform]
      }.freeze

      DEFAULT_FILE_NAMES = {
        archive: nil,
        metadata: nil,
        trace: nil,
        metrics_referee: nil,
        network_referee: nil,
        junit: 'junit.xml',
        accessibility: 'gl-accessibility.json',
        codequality: 'gl-code-quality-report.json',
        sast: 'gl-sast-report.json',
        secret_detection: 'gl-secret-detection-report.json',
        dependency_scanning: 'gl-dependency-scanning-report.json',
        container_scanning: 'gl-container-scanning-report.json',
        cluster_image_scanning: 'gl-cluster-image-scanning-report.json',
        dast: 'gl-dast-report.json',
        license_scanning: 'gl-license-scanning-report.json',
        performance: 'performance.json',
        browser_performance: 'browser-performance.json',
        load_performance: 'load-performance.json',
        metrics: 'metrics.txt',
        lsif: 'lsif.json',
        dotenv: '.env',
        cobertura: 'cobertura-coverage.xml',
        jacoco: 'jacoco-coverage.xml',
        terraform: 'tfplan.json',
        cluster_applications: 'gl-cluster-applications.json', # DEPRECATED: https://gitlab.com/gitlab-org/gitlab/-/issues/361094
        requirements: 'requirements.json', # Will be DEPRECATED soon: https://gitlab.com/groups/gitlab-org/-/epics/9203
        requirements_v2: 'requirements_v2.json',
        coverage_fuzzing: 'gl-coverage-fuzzing.json',
        api_fuzzing: 'gl-api-fuzzing-report.json',
        cyclonedx: 'gl-sbom.cdx.json',
        annotations: 'gl-annotations.json',
        repository_xray: 'gl-repository-xray.json'
      }.freeze

      INTERNAL_TYPES = {
        archive: :zip,
        metadata: :gzip,
        trace: :raw
      }.freeze

      REPORT_TYPES = {
        junit: :gzip,
        metrics: :gzip,
        metrics_referee: :gzip,
        network_referee: :gzip,
        dotenv: :gzip,
        cobertura: :gzip,
        jacoco: :gzip,
        cluster_applications: :gzip, # DEPRECATED: https://gitlab.com/gitlab-org/gitlab/-/issues/361094
        lsif: :zip,
        cyclonedx: :gzip,
        annotations: :gzip,
        repository_xray: :gzip,

        # Security reports and license scanning reports are raw artifacts
        # because they used to be fetched by the frontend, but this is not the case anymore.
        sast: :raw,
        secret_detection: :raw,
        dependency_scanning: :raw,
        container_scanning: :raw,
        cluster_image_scanning: :raw,
        dast: :raw,
        license_scanning: :raw,

        # All these file formats use `raw` as we need to store them uncompressed
        # for Frontend to fetch the files and do analysis
        # When they will be only used by backend, they can be `gzipped`.
        accessibility: :raw,
        codequality: :raw,
        performance: :raw,
        browser_performance: :raw,
        load_performance: :raw,
        terraform: :raw,
        requirements: :raw,
        requirements_v2: :raw,
        coverage_fuzzing: :raw,
        api_fuzzing: :raw
      }.freeze

      DOWNLOADABLE_TYPES = %w[
        accessibility
        api_fuzzing
        archive
        cobertura
        jacoco
        codequality
        container_scanning
        dast
        dependency_scanning
        dotenv
        junit
        license_scanning
        lsif
        metrics
        performance
        browser_performance
        load_performance
        sast
        secret_detection
        requirements
        requirements_v2
        cluster_image_scanning
        cyclonedx
      ].freeze

      def self.non_erasable_file_types
        NON_ERASABLE_FILE_TYPES
      end

      def self.report_file_types
        REPORT_FILE_TYPES
      end

      def self.default_file_names
        DEFAULT_FILE_NAMES
      end

      def self.internal_types
        INTERNAL_TYPES
      end

      def self.report_types
        REPORT_TYPES
      end

      def self.downloadable_types
        DOWNLOADABLE_TYPES
      end

      def self.type_and_format_pairs
        INTERNAL_TYPES.merge(REPORT_TYPES).freeze
      end

      # Returns the Hash to use for creating the `file_type` enum for
      # `JobArtifact`.
      def self.file_type
        {
          archive: 1,
          metadata: 2,
          trace: 3,
          junit: 4,
          sast: 5, ## EE-specific
          dependency_scanning: 6, ## EE-specific
          container_scanning: 7, ## EE-specific
          dast: 8, ## EE-specific
          codequality: 9, ## EE-specific
          license_scanning: 101, ## EE-specific
          performance: 11, ## EE-specific till 13.2
          metrics: 12, ## EE-specific
          metrics_referee: 13, ## runner referees
          network_referee: 14, ## runner referees
          lsif: 15, # LSIF data for code navigation
          dotenv: 16,
          cobertura: 17,
          terraform: 18, # Transformed json
          accessibility: 19,
          cluster_applications: 20,
          secret_detection: 21, ## EE-specific
          requirements: 22, ## EE-specific
          coverage_fuzzing: 23, ## EE-specific
          browser_performance: 24, ## EE-specific
          load_performance: 25, ## EE-specific
          api_fuzzing: 26, ## EE-specific
          cluster_image_scanning: 27, ## EE-specific
          cyclonedx: 28, ## EE-specific
          requirements_v2: 29, ## EE-specific
          annotations: 30,
          repository_xray: 31, ## EE-specific
          jacoco: 32
        }
      end

      def self.file_location
        {
          legacy_path: 1,
          hashed_path: 2
        }
      end
    end
  end
end

Enums::Ci::JobArtifact.prepend_mod_with('Enums::Ci::JobArtifact')
