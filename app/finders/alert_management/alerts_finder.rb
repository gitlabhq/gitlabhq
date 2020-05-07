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
      collection = by_iid(collection)
      sort(collection)
    end

    private

    attr_reader :current_user, :project, :params

    def by_iid(collection)
      return collection unless params[:iid]

      collection.for_iid(params[:iid])
    end

    def sort(collection)
      params[:sort] ? collection.sort_by_attribute(params[:sort]) : collection
    end

    def authorized?
      Ability.allowed?(current_user, :read_alert_management_alerts, project)
    end
  end
end
