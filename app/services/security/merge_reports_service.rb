# frozen_string_literal: true

module Security
  class MergeReportsService
    attr_reader :source_reports

    def initialize(*source_reports)
      @source_reports = source_reports
    end

    def execute
      copy_resources_to_target_report
      copy_findings_to_target
      target_report
    end

    private

    def target_report
      @target_report ||= ::Gitlab::Ci::Reports::Security::Report.new(
        source_reports.first.type,
        source_reports.first.pipeline,
        source_reports.first.created_at
      ).tap do |report|
        report.errors = source_reports.flat_map(&:errors)
        report.warnings = source_reports.flat_map(&:warnings)
      end
    end

    def copy_resources_to_target_report
      sorted_source_reports.each do |source_report|
        copy_scans_to_target(source_report)
        copy_scanners_to_target(source_report)
        copy_identifiers_to_target(source_report)
        copy_scanned_resources_to_target(source_report)
      end
    end

    def sorted_source_reports
      source_reports.sort { |a, b| a.primary_scanner_order_to(b) }
    end

    def copy_scans_to_target(source_report)
      # no need for de-duping: it's done by Report internally
      source_report.scans.values.each { |scan| target_report.add_scan(scan) }
    end

    def copy_scanners_to_target(source_report)
      # no need for de-duping: it's done by Report internally
      source_report.scanners.values.each { |scanner| target_report.add_scanner(scanner) }
    end

    def copy_identifiers_to_target(source_report)
      # no need for de-duping: it's done by Report internally
      source_report.identifiers.values.each { |identifier| target_report.add_identifier(identifier) }
    end

    def copy_scanned_resources_to_target(source_report)
      target_report.scanned_resources.concat(source_report.scanned_resources).uniq!
    end

    def copy_findings_to_target
      deduplicated_findings.sort.each { |finding| target_report.add_finding(finding) }
    end

    def deduplicated_findings
      prioritized_findings.each_with_object([[], Set.new]) do |finding, (deduplicated, seen_identifiers)|
        next if seen_identifiers.intersect?(finding.keys.to_set)

        seen_identifiers.merge(finding.keys)
        deduplicated << finding
      end.first
    end

    def prioritized_findings
      source_reports.flat_map(&:findings).sort { |a, b| a.scanner_order_to(b) }
    end
  end
end
