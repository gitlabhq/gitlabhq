# frozen_string_literal: true

ActsAsTaggableOn.strict_case_match = true

# tags_counter enables caching count of tags which results in an update whenever a tag is added or removed
# since the count is not used anywhere its better performance wise to disable this cache
ActsAsTaggableOn.tags_counter = false

# validate that counter cache is disabled
raise "Counter cache is not disabled" if
    ActsAsTaggableOn::Tagging.reflections["tag"].options[:counter_cache]

# Redirects retrieve_connection to use Ci::ApplicationRecord's connection
[::ActsAsTaggableOn::Tag, ::ActsAsTaggableOn::Tagging].each do |model|
  model.connection_specification_name = Ci::ApplicationRecord.connection_specification_name
  model.singleton_class.delegate :connection, :sticking, to: '::Ci::ApplicationRecord'
end

# Modified from https://github.com/mbleigh/acts-as-taggable-on/pull/1081
# with insert_all, which is not supported in MySQL
# See https://gitlab.com/gitlab-org/gitlab/-/issues/338346#note_996969960
module ActsAsTaggableOnTagPatch
  def find_or_create_all_with_like_by_name(*list)
    list = Array(list).flatten

    return [] if list.empty?

    existing_tags = named_any(list)

    missing = list.reject do |tag_name|
      comparable_tag_name = comparable_name(tag_name)
      existing_tags.find { |tag| comparable_name(tag.name) == comparable_tag_name }
    end

    if missing.empty?
      new_tags = []
    else
      attributes_to_add = missing.map do |tag_name|
        { name: tag_name }
      end

      insert_all(attributes_to_add, unique_by: :name)
      new_tags = named_any(missing)
    end

    existing_tags + new_tags
  end
end

::ActsAsTaggableOn::Tag.singleton_class.prepend(ActsAsTaggableOnTagPatch)
