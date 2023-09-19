# frozen_string_literal: true

module ReleaseHighlights
  class Validator::Entry
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    AVAILABLE_IN = %w[Free Premium Ultimate].freeze
    HYPHENATED_ATTRIBUTES = [:self_managed, :gitlab_com].freeze

    attr_reader :entry
    attr_accessor :available_in, :description, :gitlab_com, :image_url, :name, :published_at, :release, :self_managed,
      :stage

    validates :name, :description, :stage, presence: true
    validates :self_managed, :gitlab_com, inclusion: { in: [true, false], message: "must be a boolean" }
    validates :documentation_link, public_url: { dns_rebind_protection: true }
    validates :image_url, public_url: { dns_rebind_protection: true }, allow_nil: true
    validates :release, numericality: true
    validate :validate_published_at
    validate :validate_available_in

    after_validation :add_line_numbers_to_errors!

    def initialize(entry)
      @entry = entry
    end

    def validate_published_at
      published_at = value_for('published_at')

      return if published_at.is_a?(Date)

      errors.add(:published_at, 'must be valid Date')
    end

    def validate_available_in
      available_in = value_for('available_in')

      if !available_in.is_a?(Array) || available_in.empty? || available_in.any? { |p| AVAILABLE_IN.exclude?(p) }
        errors.add(:available_in, "must be one of #{AVAILABLE_IN}")
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
      formatted_key = key.in?(HYPHENATED_ATTRIBUTES) ? key.to_s.dasherize : key.to_s
      entry.children.find { |node| node.try(:value) == formatted_key }
    end
  end
end
