# frozen_string_literal: true

class Import::BaseController < ApplicationController
  before_action :import_rate_limit, only: [:create]

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def find_already_added_projects(import_type)
    current_user.created_projects.where(import_type: import_type).with_import_state
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def find_jobs(import_type)
    current_user.created_projects
      .with_import_state
      .where(import_type: import_type)
      .to_json(only: [:id], methods: [:import_status])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # deprecated: being replaced by app/services/import/base_service.rb
  def find_or_create_namespace(names, owner)
    names = params[:target_namespace].presence || names

    return current_user.namespace if names == owner

    group = Groups::NestedCreateService.new(current_user, group_path: names).execute

    group.errors.any? ? current_user.namespace : group
  rescue => e
    Gitlab::AppLogger.error(e)

    current_user.namespace
  end

  # deprecated: being replaced by app/services/import/base_service.rb
  def project_save_error(project)
    project.errors.full_messages.join(', ')
  end

  def import_rate_limit
    key = "project_import".to_sym

    if rate_limiter.throttled?(key, scope: [current_user, key])
      rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)

      redirect_back_or_default(options: { alert: _('This endpoint has been requested too many times. Try again later.') })
    end
  end

  def rate_limiter
    ::Gitlab::ApplicationRateLimiter
  end
end
