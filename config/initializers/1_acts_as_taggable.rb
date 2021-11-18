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
