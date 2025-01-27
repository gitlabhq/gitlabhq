# frozen_string_literal: true

module TaggableQueries
  extend ActiveSupport::Concern

  MAX_TAGS_IDS = 50

  TooManyTagsError = Class.new(StandardError)

  class_methods do
    def arel_tag_names_array
      taggings_join_model
        .scoped_taggables
        .joins(:tag)
        .select('COALESCE(array_agg(tags.name ORDER BY name), ARRAY[]::text[])')
    end
  end

  def tags_ids
    tags.limit(MAX_TAGS_IDS).order('id ASC').pluck(:id).tap do |ids|
      raise TooManyTagsError if ids.size >= MAX_TAGS_IDS
    end
  end
end
