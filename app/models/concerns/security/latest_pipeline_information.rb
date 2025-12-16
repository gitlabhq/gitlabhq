# frozen_string_literal: true

module Security
  module LatestPipelineInformation
    private

    def scanner_enabled?(scan_type)
      latest_builds_reports.include?(scan_type)
    end

    def latest_builds_reports(only_successful_builds: false)
      strong_memoize("latest_builds_reports_#{only_successful_builds}") do
        builds = latest_security_builds
        builds = builds.select { |build| build.status == 'success' } if only_successful_builds
        reports = builds.flat_map do |build|
          build.options[:artifacts][:reports].keys
        end

        normalize_for_sast_reports(reports, builds)
      end
    end

    # Because :sast_iac and :sast_advanced reports belong to a report with a name of 'sast',
    # we have to do extra checking to determine which reports have been included
    def normalize_for_sast_reports(reports, builds)
      return reports unless reports.delete(:sast)

      reports.tap do |r|
        build_names = builds.map(&:name)

        # Support both direct job names and policy-enforced job names with suffixes
        # e.g., 'kics-iac-sast', 'kics-iac-sast-0', 'kics-iac-sast:policy-123456-0'
        r.push(:sast_iac) if build_names.any? { |name| name.start_with?('kics-iac-sast') }

        # When using advanced sast, sast should also show in the report names
        # e.g., 'gitlab-advanced-sast', 'gitlab-advanced-sast-0', 'gitlab-advanced-sast:policy-123456-0'
        r.push(:sast, :sast_advanced) if build_names.any? { |name| name.start_with?('gitlab-advanced-sast') }

        # Only add :sast if there are other sast jobs besides IaC and Advanced SAST
        if build_names.any? do |name|
          name.include?('-sast') && !name.start_with?('kics-iac-sast', 'gitlab-advanced-sast')
        end
          r.push(:sast)
        end
      end.uniq
    end

    def latest_security_builds
      return [] unless latest_default_branch_pipeline

      ::Security::SecurityJobsFinder.new(pipeline: latest_default_branch_pipeline).execute +
        ::Security::LicenseComplianceJobsFinder.new(pipeline: latest_default_branch_pipeline).execute
    end

    def latest_default_branch_pipeline
      strong_memoize(:pipeline) { latest_pipeline }
    end

    def auto_devops_source?
      latest_default_branch_pipeline&.auto_devops_source?
    end
  end
end
