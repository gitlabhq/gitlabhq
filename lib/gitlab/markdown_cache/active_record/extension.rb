# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    module ActiveRecord
      module Extension
        extend ActiveSupport::Concern

        included do
          # Always exclude _html fields from attributes (including serialization).
          # They contain unredacted HTML, which would be a security issue
          alias_method :attributes_before_markdown_cache, :attributes
          def attributes
            attrs = attributes_before_markdown_cache
            html_fields = cached_markdown_fields.html_fields
            whitelisted = cached_markdown_fields.html_fields_whitelisted
            exclude_fields = html_fields - whitelisted

            exclude_fields.each do |field|
              attrs.delete(field)
            end

            if whitelisted.empty?
              attrs.delete('cached_markdown_version')
            end

            attrs
          end

          # Using before_update here conflicts with elasticsearch-model somehow
          before_create :refresh_markdown_cache, if: :invalidated_markdown_cache?
          before_update :refresh_markdown_cache, if: :invalidated_markdown_cache?
        end

        def changed_markdown_fields
          changed_attributes.keys.map(&:to_s) & cached_markdown_fields.markdown_fields.map(&:to_s)
        end

        def write_markdown_field(field_name, value)
          write_attribute(field_name, value)
        end

        def markdown_field_changed?(field_name)
          attribute_changed?(field_name)
        end

        def save_markdown(updates)
          return unless persisted? && Gitlab::Database.read_write?

          update_columns(updates)
        end
      end
    end
  end
end
