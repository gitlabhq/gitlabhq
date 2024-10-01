# frozen_string_literal: true

module Issuable # rubocop:disable Gitlab/BoundedContexts -- existing module we need for looking up callback classes
  module Callbacks
    class Labels < Base
      include ::Gitlab::Utils::StrongMemoize

      ALLOWED_PARAMS = %i[labels add_labels remove_labels label_ids add_label_ids remove_label_ids].freeze

      def after_initialize
        params[:label_ids] = params[:add_label_ids] = [] if excluded_in_new_type?
        return unless ALLOWED_PARAMS.any? { |param| params.key?(param) }
        return unless has_permission?(:"set_#{issuable.to_ability_name}_metadata")

        normalize_and_filter_label_params!

        existing_label_ids = issuable.label_ids.sort
        new_label_ids = compute_new_label_ids.sort

        issuable.label_ids = new_label_ids
        issuable.touch if issuable.persisted? && existing_label_ids != new_label_ids
      end

      private

      def normalize_and_filter_label_params!
        normalize_and_filter_param(:add_label_ids, :add_labels)
        normalize_and_filter_param(:remove_label_ids, :remove_labels, create_when_missing: false)
        normalize_and_filter_param(:label_ids, :labels)
      end

      def compute_new_label_ids
        new_label_ids = params[:label_ids] || issuable.label_ids || []

        new_label_ids |= params[:add_label_ids] if params[:add_label_ids]
        new_label_ids -= params[:remove_label_ids] if params[:remove_label_ids]

        restore_removed_locked_labels(new_label_ids.uniq)
      end

      # Restore any locked labels that the user is attempting to remove
      def restore_removed_locked_labels(new_label_ids)
        return new_label_ids unless issuable.supports_lock_on_merge?
        return new_label_ids unless issuable.label_ids.present?

        removed_label_ids = issuable.label_ids - new_label_ids
        removed_locked_label_ids = available_labels_service.filter_locked_label_ids(removed_label_ids)

        new_label_ids + removed_locked_label_ids
      end

      def normalize_and_filter_param(id_param_name, title_param_name, create_when_missing: true)
        if params[id_param_name]
          params[id_param_name] = available_labels_service.filter_labels_ids_in_param(id_param_name)
        elsif params[title_param_name]
          params[id_param_name] = available_labels_service.find_or_create_by_titles(
            title_param_name, find_only: !create_when_missing
          ).map(&:id)
        end
      end

      def available_labels_service
        ::Labels::AvailableLabelsService.new(current_user, issuable.resource_parent, params)
      end
      strong_memoize_attr :available_labels_service
    end
  end
end

Issuable::Callbacks::Labels.prepend_mod
