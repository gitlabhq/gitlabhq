# frozen_string_literal: true

module API
  module Entities
    class Milestone < Grape::Entity
      expose :id, :iid, documentation: { type: 'Integer' }
      expose :project_id, documentation: { type: 'Integer' }, if: ->(entity, options) { entity&.project_id }
      expose :group_id, if: ->(entity, options) { entity&.group_id }
      expose :title, :description
      expose :state, :created_at, :updated_at
      expose :due_date
      expose :start_date
      expose :expired, documentation: { type: 'Boolean' }

      expose :web_url do |milestone, _options|
        Gitlab::UrlBuilder.build(milestone)
      end
    end
  end
end
