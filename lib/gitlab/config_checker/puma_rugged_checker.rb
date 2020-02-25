# frozen_string_literal: true

module Gitlab
  module ConfigChecker
    module PumaRuggedChecker
      extend self
      extend Gitlab::Git::RuggedImpl::UseRugged

      def check
        return [] unless Gitlab::Runtime.puma?

        notices = []

        link_start = '<a href="https://docs.gitlab.com/ee/administration/operations/puma.html">'
        link_end = '</a>'
        notices << {
          type: 'info',
          message: _('You are running Puma, which is currently experimental. '\
                   'More information is available in our '\
                   '%{link_start}documentation%{link_end}.') % { link_start: link_start, link_end: link_end }
        }

        if running_puma_with_multiple_threads?
          link_start = '<a href="https://docs.gitlab.com/ee/administration/operations/puma.html">'
          link_end = '</a>'
          notices << {
            type: 'info',
            message: _('Puma is running with a thread count above 1. '\
                     'Information on deprecated GitLab features in this configuration is available in the '\
                     '%{link_start}documentation%{link_end}.') % { link_start: link_start, link_end: link_end }
          }
        end

        if running_puma_with_multiple_threads? && rugged_enabled_through_feature_flag?
          link_start = '<a href="https://docs.gitlab.com/ee/administration/operations/puma.html#performance-caveat-when-using-puma-with-rugged">'
          link_end = '</a>'
          notices << {
            type: 'warning',
            message: _('Puma is running with a thread count above 1 and the rugged '\
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
