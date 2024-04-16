# frozen_string_literal: true

module Organizations
  class OrganizationsController < ApplicationController
    include PreviewMarkdown
    include FiltersEvents

    DEFAULT_RESOURCE_LIMIT = 1000

    feature_category :cell

    before_action :event_filter, only: [:activity]
    before_action :authorize_read_organization!, only: [:activity, :show, :groups_and_projects]
    before_action only: [:index] do
      push_frontend_feature_flag(:allow_organization_creation, current_user)
    end

    skip_before_action :authenticate_user!, only: [:activity, :show, :groups_and_projects]

    urgency :low, [:activity]

    def index; end

    def new
      authorize_create_organization!
    end

    def show; end

    def activity
      respond_to do |format|
        format.html
        format.json do
          load_events
          @events = @events.select { |event| event.visible_to_user?(current_user) }

          render json: ::Profile::EventSerializer.new(current_user: current_user).represent(@events)
        end
      end
    end

    def groups_and_projects; end

    def users
      authorize_read_organization_user!
    end

    private

    def load_events
      @events = EventCollection.new(
        organization.projects.limit(DEFAULT_RESOURCE_LIMIT).sorted_by_activity,
        offset: params[:offset].to_i,
        filter: event_filter,
        groups: organization.groups.limit(DEFAULT_RESOURCE_LIMIT)
      ).to_a.map(&:present)

      Events::RenderService.new(current_user).execute(@events)
    end
  end
end
