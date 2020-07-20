# frozen_string_literal: true
class Packages::Dependency < ApplicationRecord
  has_many :dependency_links, class_name: 'Packages::DependencyLink'

  validates :name, :version_pattern, presence: true

  validates :name, uniqueness: { scope: :version_pattern }

  NAME_VERSION_PATTERN_TUPLE_MATCHING = '(name, version_pattern) = (?, ?)'.freeze
  MAX_STRING_LENGTH = 255.freeze
  MAX_CHUNKED_QUERIES_COUNT = 10.freeze

  def self.ids_for_package_names_and_version_patterns(names_and_version_patterns = {}, chunk_size = 50, max_rows_limit = 200)
    names_and_version_patterns.reject! { |key, value| key.size > MAX_STRING_LENGTH || value.size > MAX_STRING_LENGTH }
    raise ArgumentError, 'Too many names_and_version_patterns' if names_and_version_patterns.size > MAX_CHUNKED_QUERIES_COUNT * chunk_size

    matched_ids = []
    names_and_version_patterns.each_slice(chunk_size) do |tuples|
      where_statement = Array.new(tuples.size, NAME_VERSION_PATTERN_TUPLE_MATCHING)
                             .join(' OR ')
      ids = where(where_statement, *tuples.flatten)
              .limit(max_rows_limit + 1)
              .pluck(:id)
      matched_ids.concat(ids)

      raise ArgumentError, 'Too many Dependencies selected' if matched_ids.size > max_rows_limit
    end

    matched_ids
  end

  def self.for_package_names_and_version_patterns(names_and_version_patterns = {}, chunk_size = 50, max_rows_limit = 200)
    ids = ids_for_package_names_and_version_patterns(names_and_version_patterns, chunk_size, max_rows_limit)

    return none if ids.empty?

    id_in(ids)
  end

  def self.pluck_ids_and_names
    pluck(:id, :name)
  end

  def orphaned?
    self.dependency_links.empty?
  end
end
