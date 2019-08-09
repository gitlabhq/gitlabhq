# frozen_string_literal: true

module API
  module Helpers
    module LabelHelpers
      extend Grape::API::Helpers

      params :label_create_params do
        requires :name, type: String, desc: 'The name of the label to be created'
        requires :color, type: String, desc: "The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the allowed CSS color names"
        optional :description, type: String, desc: 'The description of label to be created'
      end

      def find_label(parent, id, include_ancestor_groups: true)
        labels = available_labels_for(parent, include_ancestor_groups: include_ancestor_groups)
        label = labels.find_by_id(id) || labels.find_by_title(id)

        label || not_found!('Label')
      end

      def get_labels(parent, entity)
        present paginate(available_labels_for(parent)),
                with: entity,
                current_user: current_user,
                parent: parent,
                with_counts: params[:with_counts]
      end

      def create_label(parent, entity)
        authorize! :admin_label, parent

        label = available_labels_for(parent).find_by_title(params[:name])
        conflict!('Label already exists') if label

        priority = params.delete(:priority)
        label_params = declared_params(include_missing: false)

        label =
          if parent.is_a?(Project)
            ::Labels::CreateService.new(label_params).execute(project: parent)
          else
            ::Labels::CreateService.new(label_params).execute(group: parent)
          end

        if label.persisted?
          if parent.is_a?(Project)
            label.prioritize!(parent, priority) if priority
          end

          present label, with: entity, current_user: current_user, parent: parent
        else
          render_validation_error!(label)
        end
      end

      def update_label(parent, entity)
        authorize! :admin_label, parent

        label = find_label(parent, params[:name], include_ancestor_groups: false)
        update_priority = params.key?(:priority)
        priority = params.delete(:priority)

        label = ::Labels::UpdateService.new(declared_params(include_missing: false)).execute(label)
        render_validation_error!(label) unless label.valid?

        if parent.is_a?(Project) && update_priority
          if priority.nil?
            label.unprioritize!(parent)
          else
            label.prioritize!(parent, priority)
          end
        end

        present label, with: entity, current_user: current_user, parent: parent
      end

      def delete_label(parent)
        authorize! :admin_label, parent

        label = find_label(parent, params[:name], include_ancestor_groups: false)

        destroy_conditionally!(label)
      end
    end
  end
end
