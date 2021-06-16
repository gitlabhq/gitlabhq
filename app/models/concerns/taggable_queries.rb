# frozen_string_literal: true

module TaggableQueries
  extend ActiveSupport::Concern

  class_methods do
    # context is a name `acts_as_taggable context`
    def arel_tag_names_array(context = :tags)
      ActsAsTaggableOn::Tagging
        .joins(:tag)
        .where("taggings.taggable_id=#{quoted_table_name}.id") # rubocop:disable GitlabSecurity/SqlInjection
        .where(taggings: { context: context, taggable_type: polymorphic_name })
        .select('COALESCE(array_agg(tags.name ORDER BY name), ARRAY[]::text[])')
    end
  end
end
