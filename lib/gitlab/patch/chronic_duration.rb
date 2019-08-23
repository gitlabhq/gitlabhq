# frozen_string_literal: true

# Fixes a bug where parsing months doesn't take into account
# the ChronicDuration.days_per_week setting
#
# We can remove this when we do a refactor and push upstream in
# https://gitlab.com/gitlab-org/gitlab-ce/issues/66637

module Gitlab
  module Patch
    module ChronicDuration
      extend ActiveSupport::Concern

      class_methods do
        def duration_units_seconds_multiplier(unit)
          return 0 unless duration_units_list.include?(unit)

          case unit
          when 'months'
            3600 * ::ChronicDuration.hours_per_day * ::ChronicDuration.days_per_month
          else
            super
          end
        end

        # ChronicDuration#output uses 1mo = 4w as the conversion so we do the same here.
        # We do need to add a special case for the default days_per_week value because
        # we want to retain existing behavior for the default case
        def days_per_month
          ::ChronicDuration.days_per_week == 7 ? 30 : ::ChronicDuration.days_per_week * 4
        end
      end
    end
  end
end
