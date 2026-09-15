# frozen_string_literal: true

class Projects::ReleasesController < Projects::ApplicationController
  ALLOWED_ORDER_BY_VALUES = %w[released_at].freeze

  # Authorize
  before_action :require_non_empty_project, except: [:index]
  before_action :release, only: %i[edit show update downloads]
  before_action :authorize_read_release!
  before_action :authorize_update_release!, only: %i[edit update]
  before_action :authorize_create_release!, only: :new
  before_action :validate_suffix_path, :fetch_latest_tag, only: :latest_permalink

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss, permission: :read_release) }
  prepend_before_action(only: [:downloads]) do
    authenticate_sessionless_user!(:download)
  end

  feature_category :release_orchestration
  urgency :low

  def index
    respond_to do |format|
      format.html do
        require_non_empty_project
      end
      format.json do
        render json: ReleaseSerializer.new.represent(releases)
      end
      format.atom do
        @releases = releases
        render layout: 'xml'
      end
    end
  end

  def downloads
    parsed_redirect_uri = URI.parse(link.url)

    if internal_url?(parsed_redirect_uri)
      redirect_to link.url
    else
      render "projects/releases/redirect", locals: { redirect_uri: parsed_redirect_uri }, layout: false
    end
  end

  def latest_permalink
    return render_404 unless @latest_tag.present?

    query_parameters_except_order_by = request.query_parameters.except(:order_by)

    redirect_url = project_release_url(@project, @latest_tag)
    redirect_url += "/#{suffix_path_param}" if suffix_path_param
    redirect_url += "?#{query_parameters_except_order_by.compact.to_param}" if query_parameters_except_order_by.present?

    redirect_to redirect_url
  end

  private

  def suffix_path_param
    params.permit(:suffix_path)[:suffix_path]
  end

  def releases(params = {})
    ReleasesFinder.new(@project, current_user, params).execute
  end

  def authorize_update_release!
    access_denied! unless can?(current_user, :update_release, release)
  end

  def release
    @release ||= project.releases.find_by_tag!(tag_param)
  end

  def link
    release.links.find_by_filepath!("/#{filepath_param}")
  end

  def tag_param
    params.permit(:tag)[:tag]
  end

  def filepath_param
    params.permit(:filepath)[:filepath]
  end

  # An order_by outside ALLOWED_ORDER_BY_VALUES is dropped so the ReleasesFinder
  # default ('released_at') applies.
  def order_by_param
    params.permit(:order_by)[:order_by].presence_in(ALLOWED_ORDER_BY_VALUES)
  end

  def fetch_latest_tag
    @latest_tag = releases(order_by: order_by_param).first&.tag
  end

  def validate_suffix_path
    Gitlab::PathTraversal.check_path_traversal!(suffix_path_param) if suffix_path_param
  end

  def internal_url?(redirect_url)
    redirect_url.host == Gitlab.config.gitlab.host && redirect_url.port == Gitlab.config.gitlab.port
  end
end
