# frozen_string_literal: true

module Integrations
  class SlackOptionService
    UnknownOptionError = Class.new(StandardError)

    OPTIONS = {
      'assignee' => SlackOptions::UserSearchHandler,
      'labels' => SlackOptions::LabelSearchHandler
    }.freeze

    def initialize(params)
      @params = params
      @search_type = params.delete(:action_id)
      @selected_value = params.delete(:value)
      @view_id = params.dig(:view, :id)
    end

    def execute
      raise UnknownOptionError, "Unable to handle option: '#{search_type}'" \
        unless option?(search_type)

      handler_class = OPTIONS[search_type]
      handler_class.new(current_user, selected_value, view_id).execute
    end

    private

    def current_user
      ChatNames::FindUserService.new(
        params.dig(:team, :id),
        params.dig(:user, :id)
      ).execute
    end

    def option?(option)
      OPTIONS.key?(option)
    end

    attr_reader :params, :search_type, :selected_value, :view_id
  end
end
