# frozen_string_literal: true

class Groups::EmailCampaignsController < Groups::ApplicationController
  include InProductMarketingHelper
  include Gitlab::Tracking::ControllerConcern

  EMAIL_CAMPAIGNS_SCHEMA_URL = 'iglu:com.gitlab/email_campaigns/jsonschema/1-0-0'

  feature_category :navigation

  before_action :check_params

  def index
    track_click
    redirect_to redirect_link
  end

  private

  def track_click
    data = {
      namespace_id: group.id,
      track: @track,
      series: @series,
      subject_line: subject_line(@track, @series)
    }

    track_self_describing_event(EMAIL_CAMPAIGNS_SCHEMA_URL, data: data)
  end

  def redirect_link
    case @track
    when :create
      create_track_url
    when :verify
      project_pipelines_url(group.projects.first)
    when :trial
      'https://about.gitlab.com/free-trial/'
    when :team
      group_group_members_url(group)
    end
  end

  def create_track_url
    [
      new_project_url,
      new_project_url(anchor: 'import_project'),
      help_page_url('user/project/repository/repository_mirroring')
    ][@series]
  end

  def check_params
    @track = params[:track]&.to_sym
    @series = params[:series]&.to_i

    track_valid = @track.in?(Namespaces::InProductMarketingEmailsService::TRACKS.keys)
    series_valid = @series.in?(0..Namespaces::InProductMarketingEmailsService::INTERVAL_DAYS.size - 1)

    render_404 unless track_valid && series_valid
  end
end
