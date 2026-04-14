# frozen_string_literal: true

module Gitlab
  module PDF
    module Security
      class VulnerabilitiesOverTime < BaseSvgChart
        TOTAL_HEIGHT = 250

        private

        def total_height
          TOTAL_HEIGHT
        end

        def title_text
          _('Vulnerabilities over time')
        end

        def description_text
          _("The number of vulnerabilities detected over time")
        end
      end
    end
  end
end
