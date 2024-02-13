# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateTopicsSlugColumn < BatchedMigrationJob
      feature_category :groups_and_projects
      scope_to ->(relation) { relation.where(slug: nil) }
      operation_name :populate_topics_slug_column

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each { |topic| topic.update! slug: clean_name(topic) }
        end
      end

      private

      def clean_name(topic)
        cleaned_name = ::Gitlab::Slug::Path.new(topic.name).generate

        Gitlab::Utils::Uniquify.new.string(cleaned_name) { |s| topic.class.find_by_slug(s) }
      end
    end
  end
end
