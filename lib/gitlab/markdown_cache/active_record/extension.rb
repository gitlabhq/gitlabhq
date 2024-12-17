# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    module ActiveRecord
      module Extension
        extend ActiveSupport::Concern

        included do
          # Using before_update here conflicts with elasticsearch-model somehow
          before_create :refresh_markdown_cache, if: :invalidated_markdown_cache?
          before_update :refresh_markdown_cache, if: :invalidated_markdown_cache?
          # The import case needs to be fixed to avoid large number of
          # SQL queries: https://gitlab.com/gitlab-org/gitlab/-/issues/21801
          after_save :run_store_mentions!, if: :mentionable_attributes_changed?, unless: ->(obj) { obj.is_a?(Importable) && obj.importing? }
        end

        def run_store_mentions!
          if store_mentions_after_commit?
            run_after_commit { store_mentions! }
          else
            store_mentions!
          end
        end

        # Always exclude _html fields from attributes (including serialization).
        # They contain unredacted HTML, which would be a security issue
        def attributes
          attrs = super
          html_fields = cached_markdown_fields.html_fields
          whitelisted = cached_markdown_fields.html_fields_whitelisted
          exclude_fields = html_fields - whitelisted

          attrs.except!(*exclude_fields)
          attrs.delete('cached_markdown_version') if whitelisted.empty?

          attrs
        end

        def write_markdown_field(field_name, value)
          write_attribute(field_name, value)
        end

        def markdown_field_changed?(field_name)
          attribute_changed?(field_name)
        end

        def save_markdown(updates)
          return unless persisted? && Gitlab::Database.read_write?
          return if cached_markdown_version.to_i < cached_markdown_version_in_database.to_i

          update_columns(updates)
        end
      end
    end
  end
end
