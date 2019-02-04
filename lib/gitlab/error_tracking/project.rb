# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class Project
      include ActiveModel::Model

      ACCESSORS = [
        :id, :name, :status, :slug, :organization_name,
        :organization_id, :organization_slug
      ].freeze

      attr_accessor(*ACCESSORS)
    end
  end
end
