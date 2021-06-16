# frozen_string_literal: true

module ReleaseHighlights
  class Validator::Entry
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    PACKAGES = %w(Free Premium Ultimate).freeze

    attr_reader :entry

    validates :title, :body, :stage, presence: true
    validates :'self-managed', :'gitlab-com', inclusion: { in: [true, false], message: "must be a boolean" }
    validates :url, :image_url, public_url: { dns_rebind_protection: true }
    validates :release, numericality: true
    validate :validate_published_at
    validate :validate_packages

    after_validation :add_line_numbers_to_errors!

    def initialize(entry)
      @entry = entry
    end

    def validate_published_at
      published_at = value_for('published_at')

      return if published_at.is_a?(Date)

      errors.add(:published_at, 'must be valid Date')
    end

    def validate_packages
      packages = value_for('packages')

      if !packages.is_a?(Array) || packages.empty? || packages.any? { |p| PACKAGES.exclude?(p) }
        errors.add(:packages, "must be one of #{PACKAGES}")
      end
    end

    def read_attribute_for_validation(key)
      value_for(key)
    end

    private

    def add_line_numbers_to_errors!
      errors.messages.each do |attribute, messages|
        extended_messages = messages.map { |m| "#{m} (line #{line_number_for(attribute)})" }

        errors.delete(attribute)
        extended_messages.each { |extended_message| errors.add(attribute, extended_message) }
      end
    end

    def line_number_for(key)
      node = find_node(key)

      (node&.start_line || @entry.start_line) + 1
    end

    def value_for(key)
      node = find_node(key)

      return if node.nil?

      index = entry.children.find_index(node)

      next_node = entry.children[index + 1]
      next_node&.to_ruby
    end

    def find_node(key)
      entry.children.find {|node| node.try(:value) == key.to_s }
    end
  end
end
