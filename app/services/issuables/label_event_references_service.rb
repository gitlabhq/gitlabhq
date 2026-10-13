# frozen_string_literal: true

module Issuables
  class LabelEventReferencesService
    def initialize(parent)
      @parent = parent
    end

    def execute(labels)
      local_label_ids = local_label_ids_for(labels)
      ResourceLabelEvent.preload_reference_containers(labels.reject { |label| local_label_ids.include?(label.id) })

      labels.index_by(&:id).transform_values do |label|
        ResourceLabelEvent.reference_for(label, parent, local_label_ids)
      end
    end

    private

    attr_reader :parent

    def local_label_ids_for(labels)
      return Set.new if parent.nil? || labels.empty?

      LabelsFinder.new(nil, ResourceLabelEvent.local_labels_finder_params(parent))
        .execute(skip_authorization: true)
        .id_in(labels.map(&:id))
        .without_order
        .pluck_primary_key
        .to_set
    end
  end
end
