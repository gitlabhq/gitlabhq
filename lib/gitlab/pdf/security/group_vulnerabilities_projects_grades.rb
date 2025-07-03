# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    module Security
      class GroupVulnerabilitiesProjectsGrades
        include Prawn::View

        DEFAULT_COUNTS = '0 projects'
        GRADES_DISPLAY_INFO = {
          a: { color: '#16a34a', severities: [] },
          b: { color: '#f97316', severities: %w[low] },
          c: { color: '#ea580c', severities: %w[medium] },
          d: { color: '#b91c1c', severities: %w[high unknown] },
          f: { color: '#991b1b', severities: %w[critical] }
        }.freeze

        SVG_STYLES = <<~SVG_STYLES.freeze
        <defs>
          <style>
            .header-text { font-family: sans-serif; font-size: 18px; font-weight: bold; fill: #1f2937; }
            .subheader { font-family: sans-serif; font-size: 13px; fill: #6b7280; }
            .grade-letter { font-family: sans-serif; font-size: 16px; font-weight: bold; }
            .project-count { font-family: sans-serif; font-size: 14px; fill: #1f2937; }
            .description { font-family: sans-serif; font-size: 12px; fill: #6b7280; }
            .severity-count { font-family: sans-serif; font-size: 11px; }
            .grade-f { fill: #{GRADES_DISPLAY_INFO.dig(:f, :color)}; }
            .grade-d { fill: #{GRADES_DISPLAY_INFO.dig(:d, :color)}; }
            .grade-c { fill: #{GRADES_DISPLAY_INFO.dig(:c, :color)}; }
            .grade-b { fill: #{GRADES_DISPLAY_INFO.dig(:b, :color)}; }
            .grade-a { fill: #{GRADES_DISPLAY_INFO.dig(:a, :color)}; }
          </style>
        </defs>
        SVG_STYLES

        def self.render(pdf, data: {})
          new(pdf, data).render
        end

        def initialize(pdf, data)
          @pdf = pdf
          @grades = process_raw(data)
          @expanded_grade = data&.fetch(:expanded_grade, 'F')
          @gitlab_host_url = Rails.application.routes.url_helpers.root_url.chomp('/')
          @width = 500
          @height = 700
          @y = pdf.cursor
        end

        def render
          return :noop if @grades.blank?

          @pdf.bounding_box([0, @y], width: @pdf.bounds.right, height: @height) do
            @pdf.save_graphics_state
            @pdf.fill_color "F9F9F9"
            @pdf.fill_rectangle [0, @pdf.bounds.top], @pdf.bounds.right, @height
            @pdf.restore_graphics_state

            @pdf.text_box(
              s_('Project security status'),
              at: [0, @pdf.bounds.top - 10],
              width: @pdf.bounds.right,
              align: :center,
              style: :bold,
              size: 16
            )

            @pdf.text_box(
              s_('Projects are graded based on the highest severity vulnerability present'),
              at: [0, @pdf.bounds.top - 40],
              width: @pdf.bounds.right,
              align: :center,
              size: 12
            )

            svg = build_base_svg
            @pdf.svg svg, at: [0, @pdf.cursor]

            render_project_names
          end
        end

        private

        def build_base_svg
          svg = <<~SVG
            <svg width="#{@pdf.bounds.width}" height="700" xmlns="http://www.w3.org/2000/svg">
              #{SVG_STYLES}
              #{svg_background_layers}
              #{svg_headers(title_y: 35, description_y: 55)}
          SVG

          current_svg_y = 80
          @project_text_positions = [] # Store positions for later text rendering

          @grades.each do |grade|
            if grade[:letter] == @expanded_grade
              expanded_drawer_height = (grade[:projects].count * 45) + 80

              if grade[:projects]
                y_position = current_svg_y + 70
                grade[:projects].each_with_index do |project, index|
                  @project_text_positions << {
                    project: project,
                    y: y_position + (index * 45),
                    grade: grade[:letter]
                  }
                end
              end

              svg += expanded_grade_svg(grade, current_svg_y, expanded_drawer_height)
              current_svg_y += expanded_drawer_height
            else
              svg += collapsed_grade_svg(grade, current_svg_y)
              current_svg_y += 40 # collapsed row height
            end
          end

          svg += '</svg>'
        end

        def svg_background_layers
          <<~SVG
            <rect x="0" y="0" width="#{@pdf.bounds.width}" height="#{@height}" fill="#ffffff"/>
            <rect x=" 0" y="0" width="#{@pdf.bounds.width}" height="80" fill="#f9fafb" stroke="#e5e7eb" stroke-width="1"/>
          SVG
        end

        def svg_headers(title_y:, description_y:)
          title = s_("Project security status")
          description = s_("Projects are graded based on the highest severity vulnerability present")

          <<~SVG
            <text x="20" y="#{title_y}" class="header-text">#{title}</text>
            <text x="20" y="#{description_y}" class="subheader">#{description}</text>
          SVG
        end

        def expanded_grade_svg(grade, current_svg_y, drawer_height)
          letter_grade = grade[:letter]
          projects = grade[:projects]

          <<~SVG
            <g transform="translate(0, #{current_svg_y})">
              <rect x="0" y="0" width="#{@pdf.bounds.width}" height="#{drawer_height}" fill="#ffffff" stroke="#e5e7eb" stroke-width="1"/>
              <rect x="0" y="0" width="#{@pdf.bounds.width}" height="40" fill="#f3f4f6"/>
              <text x="20" y="25" class="grade-letter grade-#{@expanded_grade.downcase}">#{letter_grade}</text>
              <text x="50" y="25" class="project-count">#{grade[:count]}</text>
              <text x="20" y="60" class="description">#{grade[:description]}</text>
              <g transform="translate(20, 80)">
                #{severity_counts_svg(projects, letter_grade)}
              </g>
            </g>
          SVG
        end

        def severity_counts_svg(projects, letter_grade)
          severities_included_in_grade = GRADES_DISPLAY_INFO[letter_grade.downcase.to_sym][:severities]
          y = 0

          projects.map do |project|
            y_offset = 15 # Start below where the project name would be
            svg = ""
            severities_included_in_grade.each do |severity|
              count = project['vulnerabilitySeveritiesCount'][severity]
              next if count == 0

              count_text = "#{count} #{severity}"
              severity_css = "severity-count grade-#{letter_grade.downcase}"

              svg += "<text x=\"0\" y=\"#{y + y_offset}\" class=\"#{severity_css}\">#{count_text}</text>"
              y_offset += 15
            end

            y += 45 # Move to next project position
            svg
          end.join
        end

        def collapsed_grade_svg(grade, current_svg_y)
          count = grade[:count]
          letter_grade = grade[:letter]

          <<~SVG
          <g transform="translate(0, #{current_svg_y})">
            <rect x="0" y="0" width="#{@pdf.bounds.width}" height="40" fill="#ffffff" stroke="#e5e7eb" stroke-width="1"/>
            <rect x="0" y="0" width="#{@pdf.bounds.width}" height="40" fill="#f9fafb"/>
            <text x="20" y="25" class="grade-letter grade-#{letter_grade.downcase}">#{letter_grade}</text>
            <text x="50" y="25" class="project-count">#{count}</text>
          </g>
          SVG
        end

        def render_project_names
          @project_text_positions.each do |pos|
            project_name = pos[:project]['nameWithNamespace']
            dashboard_link = @gitlab_host_url + pos[:project]['securityDashboardPath']

            @pdf.formatted_text_box(
              [{ text: project_name, color: '2563eb', link: dashboard_link }],
              at: [20, @pdf.bounds.top - pos[:y]],
              width: @pdf.bounds.width - 40,
              height: 15,
              overflow: :ellipsis,
              single_line: true,
              size: 12
            )
          end
        end

        def process_raw(data)
          grades = data.present? ? data[:vulnerability_grades] : []
          return if grades.blank?

          grade_order = %w[F D C B A]
          grades = grades.sort_by { |g| g[:grade] }.reverse!

          grade_order.map! do |letter_grade|
            if letter_grade == grades.first&.fetch(:grade)
              grade = grades.shift

              {
                letter: grade['grade'],
                count: "#{grade['count']} projects",
                projects: sort_projects(grade.dig('projects', 'nodes'))
              }
            else
              { letter: letter_grade, count: DEFAULT_COUNTS, projects: [] }
            end
          end

          grade_order
        end

        # TODO: Once the below issue is resolved, we can likely delete
        # this sorting as the projects should arrive to us sorted:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/545479
        def sort_projects(projects)
          return projects if projects.blank?

          projects.sort_by do |project|
            severities = project["vulnerabilitySeveritiesCount"]
            [
              -severities["critical"],
              -severities["high"],
              -severities["medium"],
              -severities["low"],
              -severities["info"],
              -severities["unknown"]
            ]
          end.first(5)
        end

        def severity_css(letter_grade)
          "severity-count grade-#{letter_grade.downcase}"
        end
      end
    end
  end
end
