# frozen_string_literal: true

class Packages::Dependency < ApplicationRecord
  include EachBatch

  has_many :dependency_links, class_name: 'Packages::DependencyLink'
  belongs_to :project

  validates :name, :version_pattern, :project_id, presence: true

  validates :name, uniqueness: { scope: :version_pattern }, unless: :project_id
  validates :name, uniqueness: { scope: %i[version_pattern project_id] }, if: :project_id

  NAME_VERSION_PATTERN_TUPLE_MATCHING = '(name, version_pattern) = (?, ?)'
  MAX_STRING_LENGTH = 255
  MAX_CHUNKED_QUERIES_COUNT = 10

  def self.ids_for_package_project_id_names_and_version_patterns(project_id, names_and_version_patterns = {}, chunk_size = 50, max_rows_limit = 200)
    names_and_version_patterns.reject! { |key, value| key.size > MAX_STRING_LENGTH || value.size > MAX_STRING_LENGTH }
    raise ArgumentError, 'Too many names_and_version_patterns' if names_and_version_patterns.size > MAX_CHUNKED_QUERIES_COUNT * chunk_size

    matched_ids = []
    names_and_version_patterns.each_slice(chunk_size) do |tuples|
      where_statement = Array.new(tuples.size, NAME_VERSION_PATTERN_TUPLE_MATCHING)
                             .join(' OR ')
      ids = where(where_statement, *tuples.flatten)
              .where(project_id: project_id)
              .limit(max_rows_limit + 1)
              .pluck(:id)
      matched_ids.concat(ids)

      raise ArgumentError, 'Too many Dependencies selected' if matched_ids.size > max_rows_limit
    end

    matched_ids
  end

  def self.for_package_project_id_names_and_version_patterns(project_id, names_and_version_patterns = {}, chunk_size = 50, max_rows_limit = 200)
    ids = ids_for_package_project_id_names_and_version_patterns(project_id, names_and_version_patterns, chunk_size, max_rows_limit)

    return none if ids.empty?

    id_in(ids)
  end

  def self.pluck_ids_and_names
    pluck(:id, :name)
  end

  def self.orphaned
    subquery = Packages::DependencyLink.where(Packages::DependencyLink.arel_table[:dependency_id].eq(Packages::Dependency.arel_table[:id]))
    where_not_exists(subquery)
  end

  def orphaned?
    self.dependency_links.empty?
  end
end
