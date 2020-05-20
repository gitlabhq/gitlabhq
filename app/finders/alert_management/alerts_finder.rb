# frozen_string_literal: true

module AlertManagement
  class AlertsFinder
    # @return [Hash<Integer,Integer>] Mapping of status id to count
    #          ex) { 0: 6, ...etc }
    def self.counts_by_status(current_user, project, params = {})
      new(current_user, project, params).execute.counts_by_status
    end

    def initialize(current_user, project, params)
      @current_user = current_user
      @project = project
      @params = params
    end

    def execute
      return AlertManagement::Alert.none unless authorized?

      collection = project.alert_management_alerts
      collection = by_status(collection)
      collection = by_search(collection)
      collection = by_iid(collection)
      sort(collection)
    end

    private

    attr_reader :current_user, :project, :params

    def by_iid(collection)
      return collection unless params[:iid]

      collection.for_iid(params[:iid])
    end

    def by_status(collection)
      values = AlertManagement::Alert::STATUSES.values & Array(params[:status])

      values.present? ? collection.for_status(values) : collection
    end

    def by_search(collection)
      params[:search].present? ? collection.search(params[:search]) : collection
    end

    def sort(collection)
      params[:sort] ? collection.sort_by_attribute(params[:sort]) : collection
    end

    def authorized?
      Ability.allowed?(current_user, :read_alert_management_alert, project)
    end
  end
end
