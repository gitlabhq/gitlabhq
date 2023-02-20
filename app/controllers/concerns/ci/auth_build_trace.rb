# frozen_string_literal: true

module Ci
  module AuthBuildTrace
    extend ActiveSupport::Concern

    def authorize_read_build_trace!
      return if can?(current_user, :read_build_trace, build)

      if build.debug_mode?
        access_denied!(
          _('You must have developer or higher permissions in the associated project to view job logs when debug ' \
            "trace is enabled. To disable debug trace, set the 'CI_DEBUG_TRACE' and 'CI_DEBUG_SERVICES' variables to " \
            "'false' in your pipeline configuration or CI/CD settings. If you must view this job log, " \
            'a project maintainer or owner must add you to the project with developer permissions or higher.')
        )
      else
        access_denied!(_('The current user is not authorized to access the job log.'))
      end
    end
  end
end
