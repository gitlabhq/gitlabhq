# frozen_string_literal: true

module LabelsAsHash
  extend ActiveSupport::Concern

  def labels_as_hash(target = nil, params = {})
    available_labels = LabelsFinder.new(
      current_user,
      params
    ).execute

    label_hashes = available_labels.as_json(only: [:title, :color])

    if target.respond_to?(:labels)
      already_set_labels = available_labels & target.labels
      if already_set_labels.present?
        titles = already_set_labels.map(&:title)
        label_hashes.each do |hash|
          if titles.include?(hash['title'])
            hash[:set] = true
          end
        end
      end
    end

    label_hashes
  end
end
