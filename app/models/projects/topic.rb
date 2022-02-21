# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

module Projects
  class Topic < ApplicationRecord
    include Avatarable
    include Gitlab::SQL::Pattern

    validates :name, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false }, if: :name_changed?
    validates :description, length: { maximum: 1024 }

    has_many :project_topics, class_name: 'Projects::ProjectTopic'
    has_many :projects, through: :project_topics

    scope :order_by_total_projects_count, -> { order(total_projects_count: :desc).order(id: :asc) }
    scope :reorder_by_similarity, -> (search) do
      order_expression = Gitlab::Database::SimilarityScore.build_expression(search: search, rules: [
        { column: arel_table['name'] }
      ])
      reorder(order_expression.desc, arel_table['total_projects_count'].desc, arel_table['id'])
    end

    class << self
      def search(query)
        fuzzy_search(query, [:name])
      end

      def update_non_private_projects_counter(ids_before, ids_after, project_visibility_level_before, project_visibility_level_after)
        project_visibility_level_before ||= project_visibility_level_after

        topics_to_decrement = []
        topics_to_increment = []
        topic_ids_removed = ids_before - ids_after
        topic_ids_retained = ids_before & ids_after
        topic_ids_added = ids_after - ids_before

        if project_visibility_level_before > Gitlab::VisibilityLevel::PRIVATE
          topics_to_decrement += topic_ids_removed
          topics_to_decrement += topic_ids_retained if project_visibility_level_after == Gitlab::VisibilityLevel::PRIVATE
        end

        if project_visibility_level_after > Gitlab::VisibilityLevel::PRIVATE
          topics_to_increment += topic_ids_added
          topics_to_increment += topic_ids_retained if project_visibility_level_before == Gitlab::VisibilityLevel::PRIVATE
        end

        where(id: topics_to_increment).update_counters(non_private_projects_count: 1) unless topics_to_increment.empty?
        where(id: topics_to_decrement).where('non_private_projects_count > 0').update_counters(non_private_projects_count: -1) unless topics_to_decrement.empty?
      end
    end
  end
end

::Projects::Topic.prepend_mod_with('Projects::Topic')
