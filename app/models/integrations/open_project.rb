# frozen_string_literal: true

module Integrations
  class OpenProject < BaseIssueTracker
    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true, if: :activated?
    validates :token, presence: true, if: :activated?
    validates :project_identifier_code, presence: true, if: :activated?

    data_field :url, :api_url, :token, :closed_status_id, :project_identifier_code

    def data_fields
      open_project_tracker_data || self.build_open_project_tracker_data
    end

    def self.to_param
      'open_project'
    end
  end
end
