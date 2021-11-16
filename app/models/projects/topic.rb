# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

module Projects
  class Topic < ApplicationRecord
    include Avatarable
    include Gitlab::SQL::Pattern

    validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
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
    end
  end
end

::Projects::Topic.prepend_mod_with('Projects::Topic')
