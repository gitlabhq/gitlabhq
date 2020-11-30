# frozen_string_literal: true

class Projects::StaticSiteEditorController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit

  layout 'fullscreen'

  content_security_policy do |policy|
    next if policy.directives.blank?

    frame_src_values = Array.wrap(policy.directives['frame-src']) | ['https://www.youtube.com']
    policy.frame_src(*frame_src_values)
  end

  prepend_before_action :authenticate_user!, only: [:show]
  before_action :assign_ref_and_path, only: [:show]
  before_action :authorize_edit_tree!, only: [:show]

  feature_category :static_site_editor

  def index
    render_404
  end

  def show
    service_response = ::StaticSiteEditor::ConfigService.new(
      container: project,
      current_user: current_user,
      params: {
        ref: @ref,
        path: @path,
        return_url: params[:return_url]
      }
    ).execute

    if service_response.success?
      Gitlab::UsageDataCounters::StaticSiteEditorCounter.increment_views_count

      @data = serialize_necessary_payload_values_to_json(service_response.payload)
    else
      # TODO: For now, if the service returns any error, the user is redirected
      #       to the root project page with the error message displayed as an alert.
      #       See https://gitlab.com/gitlab-org/gitlab/-/issues/213285#note_414808004
      #       for discussion of plans to handle this via a page owned by the Static Site Editor.
      flash[:alert] = service_response.message
      redirect_to project_path(project)
    end
  end

  private

  def serialize_necessary_payload_values_to_json(payload)
    # This will convert booleans, Array-like and Hash-like objects to JSON
    payload.transform_values do |value|
      if value.is_a?(String) || value.is_a?(Integer)
        value
      elsif value.nil?
        ''
      else
        value.to_json
      end
    end
  end

  def assign_ref_and_path
    @ref, @path = extract_ref(params.fetch(:id))

    render_404 if @ref.blank? || @path.blank?
  end
end
