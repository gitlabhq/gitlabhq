# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

module Projects
  class Topic < ApplicationRecord
    include Avatarable
    include CacheMarkdownField
    include Gitlab::SQL::Pattern

    SLUG_ALLOWED_REGEX = %r{\A[a-zA-Z0-9_\-.]+\z}

    cache_markdown_field :description

    validates :name, presence: true, length: { maximum: 255 }
    validates :description, length: { maximum: 1024 }
    validates :name, uniqueness: { scope: :organization_id, case_sensitive: false }, if: :name_changed?
    validate :validate_name_format, if: :name_changed?

    validates :slug,
      length: { maximum: 255 },
      uniqueness: { scope: :organization_id, case_sensitive: false },
      format: { with: SLUG_ALLOWED_REGEX, message: "can contain only letters, digits, '_', '-', '.'" },
      if: :slug_changed?

    validates :title, presence: true, length: { maximum: 255 }, on: :create
    validates :description, length: { maximum: 1024 }

    belongs_to :organization, class_name: 'Organizations::Organization'

    has_many :project_topics, class_name: 'Projects::ProjectTopic'
    has_many :projects, through: :project_topics

    scope :for_organization, ->(organization_id) { where(organization_id: organization_id) }
    scope :without_assigned_projects, -> { where(total_projects_count: 0) }
    scope :order_by_non_private_projects_count, -> { order(non_private_projects_count: :desc).order(id: :asc) }
    scope :reorder_by_similarity, ->(search) do
      order_expression = Gitlab::Database::SimilarityScore.build_expression(
        search: search,
        rules: [
          { column: arel_table['name'] }
        ])
      reorder(order_expression.desc, arel_table['non_private_projects_count'].desc, arel_table['id'])
    end

    def title_or_name
      title || name
    end

    class << self
      def find_by_name_case_insensitive(name)
        find_by('LOWER(name) = ?', name.downcase)
      end

      def search(query)
        fuzzy_search(query, [:name, :title])
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

    def uploads_sharding_key
      { organization_id: organization_id }
    end

    private

    def validate_name_format
      return if name.blank?

      case name
      when /\R/
        # /\R/ - A linebreak: \n, \v, \f, \r \u0085 (NEXT LINE),
        # \u2028 (LINE SEPARATOR), \u2029 (PARAGRAPH SEPARATOR) or \r\n.
        errors.add(:name, 'has characters that are not allowed')
      when /[^\p{ASCII}]/
        # when not ASCII characters
        errors.add(:name, 'must only include ASCII characters')
      end
    end
  end
end

::Projects::Topic.prepend_mod_with('Projects::Topic')
