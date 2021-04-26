# frozen_string_literal: true

class Import::BaseController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_action :import_rate_limit, only: [:create]
  feature_category :importers

  def status
    respond_to do |format|
      format.json do
        render json: { imported_projects: serialized_imported_projects,
                       provider_repos: serialized_provider_repos,
                       incompatible_repos: serialized_incompatible_repos,
                       namespaces: serialized_namespaces }
      end
      format.html
    end
  end

  def realtime_changes
    Gitlab::PollingInterval.set_header(response, interval: 3_000)

    render json: already_added_projects.to_json(only: [:id], methods: [:import_status])
  end

  protected

  def importable_repos
    raise NotImplementedError
  end

  def incompatible_repos
    raise NotImplementedError
  end

  def provider_name
    raise NotImplementedError
  end

  def provider_url
    raise NotImplementedError
  end

  def extra_representation_opts
    {}
  end

  private

  def sanitized_filter_param
    @filter ||= sanitize(params[:filter])&.downcase
  end

  def filtered(collection)
    return collection unless sanitized_filter_param

    collection.select { |item| item[:name].to_s.downcase.include?(sanitized_filter_param) }
  end

  def serialized_provider_repos
    Import::ProviderRepoSerializer.new(current_user: current_user).represent(importable_repos, provider: provider_name, provider_url: provider_url, **extra_representation_opts)
  end

  def serialized_incompatible_repos
    Import::ProviderRepoSerializer.new(current_user: current_user).represent(incompatible_repos, provider: provider_name, provider_url: provider_url, **extra_representation_opts)
  end

  def serialized_imported_projects
    ProjectSerializer.new.represent(already_added_projects, serializer: :import, provider_url: provider_url)
  end

  def already_added_projects
    @already_added_projects ||= filtered(find_already_added_projects(provider_name))
  end

  def serialized_namespaces
    NamespaceSerializer.new.represent(namespaces)
  end

  def namespaces
    current_user.manageable_groups_with_routes
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def find_already_added_projects(import_type)
    current_user.created_projects.where(import_type: import_type).with_import_state
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # deprecated: being replaced by app/services/import/base_service.rb
  def find_or_create_namespace(names, owner)
    names = params[:target_namespace].presence || names

    return current_user.namespace if names == owner

    group = Groups::NestedCreateService.new(current_user, group_path: names).execute

    group.errors.any? ? current_user.namespace : group
  rescue StandardError => e
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
