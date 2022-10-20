# frozen_string_literal: true

module Projects
  module IncidentManagement
    class TimelineEventsController < Projects::ApplicationController
      include PreviewMarkdown

      before_action :authenticate_user!

      respond_to :json

      feature_category :incident_management
      urgency :low
    end
  end
end
