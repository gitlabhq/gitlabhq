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

    def matches_tag_ids(tag_ids, table: quoted_table_name, column: 'id')
      matcher = ::ActsAsTaggableOn::Tagging
        .where(taggable_type: CommitStatus.name)
        .where(context: 'tags')
        .where("taggable_id = #{connection.quote_table_name(table)}.#{connection.quote_column_name(column)}") # rubocop:disable GitlabSecurity/SqlInjection
        .where.not(tag_id: tag_ids)
        .select('1')

      where("NOT EXISTS (?)", matcher)
    end

    def with_any_tags(table: quoted_table_name, column: 'id')
      matcher = ::ActsAsTaggableOn::Tagging
        .where(taggable_type: CommitStatus.name)
        .where(context: 'tags')
        .where("taggable_id = #{connection.quote_table_name(table)}.#{connection.quote_column_name(column)}") # rubocop:disable GitlabSecurity/SqlInjection
        .select('1')

      where("EXISTS (?)", matcher)
    end
  end
end
