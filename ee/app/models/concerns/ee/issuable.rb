# frozen_string_literal: true

module EE
  module Issuable
    extend ActiveSupport::Concern

    class_methods do
      def labels_hash
        issue_labels = Hash.new { |h, k| h[k] = [] }

        relation = unscoped.where(id: self.select(:id)).eager_load(:labels)
        relation.pluck(:id, 'labels.title').each do |issue_id, label|
          issue_labels[issue_id] << label
        end

        issue_labels
      end
    end
  end
end
