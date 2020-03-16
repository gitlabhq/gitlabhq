# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module PumaRuggedChecker
      extend self
      extend Gitlab::Git::RuggedImpl::UseRugged

      def check
        notices = []

        if running_puma_with_multiple_threads? && rugged_enabled_through_feature_flag?
          link_start = '<a href="https://docs.gitlab.com/ee/administration/operations/puma.html#performance-caveat-when-using-puma-with-rugged">'
          link_end = '</a>'
          notices << {
            type: 'warning',
            message: _('Puma is running with a thread count above 1 and the Rugged '\
                     'service is enabled. This may decrease performance in some environments. '\
                     'See our %{link_start}documentation%{link_end} '\
                     'for details of this issue.') % { link_start: link_start, link_end: link_end }
          }
        end

        notices
      end
    end
  end
end
