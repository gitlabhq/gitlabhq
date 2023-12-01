# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    module Redis
      module Extension
        extend ActiveSupport::Concern

        attr_reader :cached_markdown_version

        class_methods do
          def cache_markdown_field(markdown_field, context = {})
            super

            # define the `[field]_html` accessor
            html_field = cached_markdown_fields.html_field(markdown_field)
            define_method(html_field) do
              load_cached_markdown unless markdown_data_loaded?

              instance_variable_get("@#{html_field}")
            end
          end
        end

        prepended do
          def self.preload_markdown_cache!(objects)
            fields = Gitlab::MarkdownCache::Redis::Store.bulk_read(objects)

            objects.each do |object|
              fields[object.cache_key].each do |field_name, value|
                object.write_markdown_field(field_name, value)
              end
            end
          end
        end

        def write_markdown_field(field_name, value)
          # The value read from redis is a string, so we're converting it back
          # to an int.
          value = value.to_i if field_name == :cached_markdown_version

          instance_variable_set("@#{field_name}", value)
        end

        private

        def save_markdown(updates)
          markdown_store.save(updates)
        end

        def markdown_field_changed?(field_name)
          false
        end

        def changed_attributes
          {}
        end

        def cached_markdown
          @cached_data ||= markdown_store.read
        end

        def load_cached_markdown
          cached_markdown.each do |field_name, value|
            write_markdown_field(field_name, value)
          end
        end

        def markdown_data_loaded?
          cached_markdown_version.present? || markdown_store.loaded?
        end

        def markdown_store
          @store ||= Gitlab::MarkdownCache::Redis::Store.new(self)
        end
      end
    end
  end
end
