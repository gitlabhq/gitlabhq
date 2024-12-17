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

        r.push(:sast_iac) if build_names.delete('kics-iac-sast')

        # When using adavanced sast, sast should also show in the report names
        r.push(:sast, :sast_advanced) if build_names.delete('gitlab-advanced-sast')

        r.push(:sast) if build_names.any? { |name| name.include? '-sast' }
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
