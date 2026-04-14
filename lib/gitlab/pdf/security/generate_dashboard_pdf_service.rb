# frozen_string_literal: true

module Gitlab
  module PDF
    module Security
      class GenerateDashboardPdfService
        HEADER_SPACING = 60
        SECTION_SPACING = 20

        def initialize(filename, report_data, exportable)
          @filename = filename
          @report_data = report_data
          @exportable = exportable
          @pdf = Prawn::Document.new
          @section_pages = []
          @first_section = true
        end

        attr_reader :filename, :report_data, :pdf, :section_pages, :exportable

        def execute
          render_vulnerability_history
          render_vulnerabilities_severity_count
          render_group_security_status
          render_total_risk_score
          render_vulnerabilities_over_time
          render_vulnerabilities_by_age

          draw_header
          setup_index_tree
          pdf.render_file(filename)
        end

        private

        def exportable_group?
          exportable.is_a? Group
        end

        def ensure_space_for(height)
          if pdf.cursor >= height + SECTION_SPACING
            pdf.move_down SECTION_SPACING
          else
            pdf.start_new_page
            pdf.move_down HEADER_SPACING
          end
        end

        def start_new_section
          if @first_section
            pdf.move_down HEADER_SPACING
            @first_section = false
          else
            pdf.start_new_page
            pdf.move_down HEADER_SPACING
          end
        end

        def add_section_page(title, page_number)
          section_pages << { title: title, destination: page_number }
        end

        def draw_header
          pdf.repeat(:all, dynamic: true) do
            Gitlab::PDF::Header.render(pdf, exportable.name, page: pdf.page_number, height: 50)
          end
        end

        def setup_index_tree
          section_pages.each do |section|
            pdf.outline.page(title: section[:title], destination: section[:destination])
          end
        end

        # Vulnerability History

        def should_render_vulnerability_history?
          report_data['project_vulnerabilities_history'].present? ||
            report_data['group_vulnerabilities_over_time'].present?
        end

        def render_vulnerability_history
          return unless should_render_vulnerability_history?

          start_new_section
          add_section_page(_('Vulnerabilities History'), pdf.page_number)
          draw_vulnerability_history_graphs
        end

        def draw_vulnerability_history_graphs
          Gitlab::PDF::Security::ProjectVulnerabilitiesHistory.render(
            pdf, data: report_data['project_vulnerabilities_history']
          )

          Gitlab::PDF::Security::GroupVulnerabilitiesHistory.render(
            pdf, data: report_data['group_vulnerabilities_over_time']
          )
        end

        # Vulnerabilities by Severity Count: always rendered even without data

        def render_vulnerabilities_severity_count
          start_new_section
          add_section_page(_('Vulnerabilities By Severity Count'), pdf.page_number)
          draw_vulnerabilities_by_severity_count
        end

        def draw_vulnerabilities_by_severity_count
          Gitlab::PDF::Security::VulnerabilitiesBySeverityCount.render(
            pdf, data: report_data['vulnerabilities_by_severity_count']
          )
        end

        # Project/Group Security Status

        def should_render_group_security_status?
          exportable_group? && report_data['project_security_status'].present?
        end

        def render_group_security_status
          return unless should_render_group_security_status?

          pdf.move_down SECTION_SPACING
          add_section_page(_('Project Security Status'), pdf.page_number)
          draw_group_security_status
        end

        def draw_group_security_status
          Gitlab::PDF::Security::GroupVulnerabilitiesProjectsGrades.render(
            pdf, data: report_data['project_security_status']
          )
        end

        # Total Risk Score

        def should_render_total_risk_score?
          report_data['total_risk_score'].present?
        end

        def render_total_risk_score
          return unless should_render_total_risk_score?

          ensure_space_for(Gitlab::PDF::Security::TotalRiskScore::TOTAL_HEIGHT)
          add_section_page(_('Total Risk Score'), pdf.page_number)
          draw_total_risk_score
        end

        def draw_total_risk_score
          Gitlab::PDF::Security::TotalRiskScore.render(
            pdf, data: report_data['total_risk_score']
          )
        end

        # Vulnerabilities Over Time

        def should_render_vulnerabilities_over_time?
          report_data['open_vulnerabilities_over_time'].present?
        end

        def render_vulnerabilities_over_time
          return unless should_render_vulnerabilities_over_time?

          ensure_space_for(Gitlab::PDF::Security::VulnerabilitiesOverTime::TOTAL_HEIGHT)
          add_section_page(_('Vulnerabilities Over Time'), pdf.page_number)
          draw_vulnerabilities_over_time
        end

        def draw_vulnerabilities_over_time
          Gitlab::PDF::Security::VulnerabilitiesOverTime.render(
            pdf, data: report_data['open_vulnerabilities_over_time']
          )
        end

        # Vulnerabilities by Age

        def should_render_vulnerabilities_by_age?
          report_data['vulnerabilities_by_age'].present?
        end

        def render_vulnerabilities_by_age
          return unless should_render_vulnerabilities_by_age?

          ensure_space_for(Gitlab::PDF::Security::VulnerabilitiesByAge::TOTAL_HEIGHT)
          add_section_page(_('Vulnerabilities By Age'), pdf.page_number)
          draw_vulnerabilities_by_age
        end

        def draw_vulnerabilities_by_age
          Gitlab::PDF::Security::VulnerabilitiesByAge.render(
            pdf, data: report_data['vulnerabilities_by_age']
          )
        end
      end
    end
  end
end
