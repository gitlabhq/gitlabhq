# frozen_string_literal: true

module Admin
  module JobsHelper
    def admin_jobs_app_data
      {
        job_statuses: job_statuses.to_json,
        url: cancel_all_admin_jobs_path,
        can_update_all_jobs: current_user.can_admin_all_resources?.to_s
      }
    end
  end
end
