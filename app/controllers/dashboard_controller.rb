# frozen_string_literal: true

class DashboardController < Dashboard::ApplicationController
  include IssuableCollectionsAction
  include FiltersEvents

  prepend_before_action(only: [:issues]) { authenticate_sessionless_user!(:rss) }
  prepend_before_action(only: [:issues_calendar]) { authenticate_sessionless_user!(:ics) }

  before_action :event_filter, only: :activity
  before_action :projects, only: [:issues, :merge_requests]
  before_action :set_show_full_reference, only: [:issues, :merge_requests]
  before_action :check_filters_presence!, only: [:issues, :merge_requests]

  respond_to :html

  feature_category :users, [:activity]
  feature_category :issue_tracking, [:issues, :issues_calendar]
  feature_category :code_review, [:merge_requests]

  def activity
    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json('events/_events', @events.count { |event| event.visible_to_user?(current_user) })
      end
    end
  end

  protected

  def load_events
    @events =
      if params[:filter] == "followed"
        load_user_events
      else
        load_project_events
      end

    Events::RenderService.new(current_user).execute(@events)
  end

  def load_user_events
    UserRecentEventsFinder.new(current_user, current_user.followees, event_filter, params).execute
  end

  def load_project_events
    projects =
      if params[:filter] == "starred"
        ProjectsFinder.new(current_user: current_user, params: { starred: true }).execute
      else
        current_user.authorized_projects
      end

    EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a
      .map(&:present)
  end

  def set_show_full_reference
    @show_full_reference = true
  end

  def check_filters_presence!
    no_scalar_filters_set = finder_type.scalar_params.none? { |k| params.key?(k) }
    no_array_filters_set = finder_type.array_params.none? { |k, _| params.key?(k) }

    @no_filters_set = no_scalar_filters_set && no_array_filters_set

    return unless @no_filters_set

    # Call to set selected `state` and `sort` options in view
    finder_options

    respond_to do |format|
      format.html { render }
      format.atom { head :bad_request }
    end
  end
end
