# frozen_string_literal: true

class Projects::ProductAnalyticsController < Projects::ApplicationController
  before_action :feature_enabled!
  before_action :authorize_read_product_analytics!
  before_action :tracker_variables, only: [:setup, :test]

  feature_category :product_analytics

  def index
    @events = product_analytics_events.order_by_time.page(params[:page])
  end

  def setup
  end

  def test
    @event = product_analytics_events.try(:first)
  end

  def graphs
    @graphs = []
    @timerange = 30

    requested_graphs = %w(platform os_timezone br_lang doc_charset)

    requested_graphs.each do |graph|
      @graphs << ProductAnalytics::BuildGraphService
        .new(project, { graph: graph, timerange: @timerange })
        .execute
    end

    @activity_graph = ProductAnalytics::BuildActivityGraphService
      .new(project, { timerange: @timerange })
      .execute
  end

  private

  def product_analytics_events
    @project.product_analytics_events
  end

  def tracker_variables
    # We use project id as Snowplow appId
    @project_id = @project.id.to_s

    # Snowplow remembers values like appId and platform between reloads.
    # That is why we have to rename the tracker with a random integer.
    @random = rand(999999)

    # Generate random platform every time a tracker is rendered.
    @platform = %w(web mob app)[(@random % 3)]
  end

  def feature_enabled!
    render_404 unless Feature.enabled?(:product_analytics, @project, default_enabled: false)
  end
end
