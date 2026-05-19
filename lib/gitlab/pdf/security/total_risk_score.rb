# frozen_string_literal: true

module Gitlab
  module PDF
    module Security
      class TotalRiskScore < BaseSvgChart
        # the SVG provided by the frontend uses CSS variables, but
        # prawn-svg does not support CSS variables. We will gsub in
        # hardcoded colors for the CSS variables we care about.
        CSS_TRANSLATIONS = [
          ['var(--gl-chart-axis-line-color)', '#dddddd'],
          ['var(--gl-text-color-default)', '#333333'],
          ['var(--gl-chart-axis-text-color)', '#666666'],
          ['var(--risk-score-color-low)', '#16a34a'],
          ['var(--risk-score-color-medium)', '#f97316'],
          ['var(--risk-score-color-high)', '#ea580c'],
          ['var(--risk-score-color-critical)', '#b91c1c'],
          ['var(--risk-score-gauge-text-low)', '#16a34a'],
          ['var(--risk-score-gauge-text-medium)', '#f97316'],
          ['var(--risk-score-gauge-text-high)', '#ea580c'],
          ['var(--risk-score-gauge-text-critical)', '#b91c1c']
        ].freeze

        TOTAL_HEIGHT = 250

        private

        def total_height
          TOTAL_HEIGHT
        end

        def title_text
          _('Total Risk Score')
        end

        def description_text
          _("The overall risk score for your organization based on vulnerability severity and age.")
        end

        def css_translations
          CSS_TRANSLATIONS
        end
      end
    end
  end
end
