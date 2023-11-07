# frozen_string_literal: true
module Packages
  class UpdateTagsService
    include Gitlab::Utils::StrongMemoize

    def initialize(package, tags = [])
      @package = package
      @tags = tags
    end

    def execute
      return if @tags.empty?

      tags_to_destroy = existing_tags - @tags
      tags_to_create = @tags - existing_tags

      @package.tags.with_name(tags_to_destroy).delete_all if tags_to_destroy.any?
      ::ApplicationRecord.legacy_bulk_insert(Packages::Tag.table_name, rows(tags_to_create)) if tags_to_create.any? # rubocop:disable Gitlab/BulkInsert
    end

    private

    def existing_tags
      @package.tag_names
    end
    strong_memoize_attr :existing_tags

    def rows(tags)
      now = Time.zone.now
      tags.map do |tag|
        {
          package_id: @package.id,
          name: tag,
          created_at: now,
          updated_at: now,
          project_id: @package.project_id
        }
      end
    end
  end
end
