# frozen_string_literal: true

ActsAsTaggableOn.strict_case_match = true

# tags_counter enables caching count of tags which results in an update whenever a tag is added or removed
# since the count is not used anywhere its better performance wise to disable this cache
ActsAsTaggableOn.tags_counter = false

# validate that counter cache is disabled
raise "Counter cache is not disabled" if
    ActsAsTaggableOn::Tagging.reflections["tag"].options[:counter_cache]

ActsAsTaggableOn::Tagging.include IgnorableColumns
ActsAsTaggableOn::Tagging.ignore_column :id_convert_to_bigint, remove_with: '14.2', remove_after: '2021-08-22'
ActsAsTaggableOn::Tagging.ignore_column :taggable_id_convert_to_bigint, remove_with: '14.2', remove_after: '2021-08-22'
