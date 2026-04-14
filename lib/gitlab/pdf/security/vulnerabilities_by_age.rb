# frozen_string_literal: true

module Gitlab
  module PDF
    module Security
      class VulnerabilitiesByAge < BaseSvgChart
        TOTAL_HEIGHT = 250

        private

        def total_height
          TOTAL_HEIGHT
        end

        def title_text
          _('Vulnerabilities by age')
        end

        def description_text
          _("The number of vulnerabilities detected by age")
        end
      end
    end
  end
end
