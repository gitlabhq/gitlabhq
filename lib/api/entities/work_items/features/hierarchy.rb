# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Hierarchy < Grape::Entity
          expose :parent,
            using: ::API::Entities::WorkItems::Features::WorkItemReference,
            expose_nil: true,
            documentation: { type: 'Entities::WorkItems::Features::WorkItemReference' } do |widget, options|
            parent = widget.parent
            next unless parent && Ability.allowed?(options[:current_user], :read_work_item, parent)

            parent
          end

          expose :has_parent,
            documentation: { type: 'Boolean', example: false } do |widget|
            widget.parent.present?
          end
        end
      end
    end
  end
end
