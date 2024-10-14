# frozen_string_literal: true

module TaggableQueries
  extend ActiveSupport::Concern

  MAX_TAGS_IDS = 50

  TooManyTagsError = Class.new(StandardError)

  class_methods do
    # context is a name `acts_as_taggable context`
    def arel_tag_names_array(context = :tags)
      Ci::Tagging
        .joins(:tag)
        .where("taggings.taggable_id=#{quoted_table_name}.id") # rubocop:disable GitlabSecurity/SqlInjection
        .where(taggings: { context: context, taggable_type: polymorphic_name })
        .select('COALESCE(array_agg(tags.name ORDER BY name), ARRAY[]::text[])')
    end
  end

  def tags_ids
    tags_ids_relation.limit(MAX_TAGS_IDS).order('id ASC').pluck(:id).tap do |ids|
      raise TooManyTagsError if ids.size >= MAX_TAGS_IDS
    end
  end

  def tags_ids_relation
    tags
  end
end
