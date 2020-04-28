# frozen_string_literal: true

module AlertManagement
  class AlertsFinder
    def initialize(current_user, project, params)
      @current_user = current_user
      @project = project
      @params = params
    end

    def execute
      return AlertManagement::Alert.none unless authorized?

      collection = project.alert_management_alerts
      by_iid(collection)
    end

    private

    attr_reader :current_user, :project, :params

    def by_iid(collection)
      return collection unless params[:iid]

      collection.for_iid(params[:iid])
    end

    def authorized?
      Ability.allowed?(current_user, :read_alert_management_alerts, project)
    end
  end
end
