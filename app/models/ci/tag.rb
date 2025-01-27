# frozen_string_literal: true

module Ci
  class Tag < Ci::ApplicationRecord
    include Gitlab::SQL::Pattern

    self.table_name = :tags

    has_many :job_taggings, class_name: 'Ci::BuildTag'
    has_many :runner_taggings, class_name: 'Ci::RunnerTagging'

    validates :name, presence: true
    validates :name, uniqueness: { case_sensitive: true }
    validates :name, length: { maximum: 255 }

    scope :named, ->(name) { where(name: name) }
    scope :named_like, ->(name) { fuzzy_search(name, [:name]) }

    scope :named_any, ->(list) do
      list.map { |name| named(name) }.reduce(:or)
    end

    def self.find_or_create_with_like_by_name(name)
      find_or_create_all_with_like_by_name([name]).first
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = Array(list).flatten

      return [] if list.empty?

      existing_tags = named_any(list)

      missing = list.reject do |tag_name|
        existing_tags.find { |tag| tag.name == tag_name }
      end

      if missing.empty?
        new_tags = []
      else
        attributes_to_add = missing.map do |tag_name|
          { name: tag_name }
        end

        insert_all(attributes_to_add, unique_by: :name)
        new_tags = named_any(missing)
      end

      existing_tags + new_tags
    end

    def ==(other)
      super || (other.is_a?(Tag) && name == other.name)
    end

    def to_s
      name
    end
  end
end
