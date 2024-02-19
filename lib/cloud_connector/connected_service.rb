# frozen_string_literal: true

# Presents a service enabled through Cloud Connector
module CloudConnector
  class ConnectedService
    def initialize(name:, cut_off_date:)
      @name = name
      @cut_off_date = cut_off_date
    end

    def free_access?
      cut_off_date.nil? || cut_off_date&.future?
    end

    attr_accessor :name, :cut_off_date
  end
end
