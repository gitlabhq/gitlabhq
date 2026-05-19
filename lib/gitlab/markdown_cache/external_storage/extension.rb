# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    module ExternalStorage
      module Extension
        extend ActiveSupport::Concern

        prepended do
          include Gitlab::ExternallyStoredField
        end

        class_methods do
          def cache_markdown_field(markdown_field, context = {})
            if context.delete(:storage) == :external
              externally_stored_field markdown_field
              externally_stored_field :"#{markdown_field}_html"
            end

            super
          end
        end

        def write_markdown_field(field_name, value)
          if externally_stored_field?(field_name)
            write_attribute(field_name, value)
          else
            super
          end
        end

        def markdown_field_changed?(field_name)
          if externally_stored_field?(field_name)
            attribute_changed?(field_name)
          else
            super
          end
        end

        def save_markdown(updates)
          external_updates = {}
          ar_updates = {}

          updates.each do |field_name, value|
            if externally_stored_field?(field_name)
              external_updates[field_name] = value
            else
              ar_updates[field_name] = value
            end
          end

          persist_external_payload(updates: external_updates) if external_updates.any?
          super(ar_updates) if ar_updates.any?
        end
      end
    end
  end
end
