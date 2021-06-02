# frozen_string_literal: true

class Groups::EmailCampaignsController < Groups::ApplicationController
  EMAIL_CAMPAIGNS_SCHEMA_URL = 'iglu:com.gitlab/email_campaigns/jsonschema/1-0-0'

  feature_category :navigation

  before_action :check_params

  def index
    track_click
    redirect_to redirect_link
  end

  private

  def track_click
    if Gitlab.com?
      message = Gitlab::Email::Message::InProductMarketing.for(@track).new(group: group, user: current_user, series: @series)

      data = {
        namespace_id: group.id,
        track: @track.to_s,
        series: @series,
        subject_line: message.subject_line
      }
      context = SnowplowTracker::SelfDescribingJson.new(EMAIL_CAMPAIGNS_SCHEMA_URL, data)

      ::Gitlab::Tracking.event(self.class.name, 'click', context: [context], user: current_user, namespace: group)
    else
      ::Users::InProductMarketingEmail.save_cta_click(current_user, @track, @series)
    end
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
    return render_404 unless track_valid

    series_valid = @series.in?(0..Namespaces::InProductMarketingEmailsService::TRACKS[@track][:interval_days].size - 1)
    render_404 unless series_valid
  end
end
