# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      # Finds or creates a label for issues that were imported with a custom
      # work item type name that could not be resolved in the target namespace.
      #
      # During import, when a work item type cannot be resolved by name (either
      # the name does not match any type, or the matched type is not usable in
      # the target context), the issue is assigned the default issue type and
      # tagged with this label so users can identify these records post-import.
      #
      # The label ID is cached in Redis per (project, type_name) to keep
      # per-issue lookups O(1) within a single import run.
      class MissingWorkItemTypeLabel
        CACHE_KEY = 'import-export/missing-work-item-type-label/%{project_id}/%{name}'
        CACHE_TIMEOUT = 5.minutes.to_i

        def initialize(project)
          @project = project
        end

        # Returns the Label#id for the given missing type name, find-or-creating
        # the label if necessary. Caches the resolved ID in Redis for CACHE_TIMEOUT.
        def id_for(type_name)
          cache_key = format(CACHE_KEY, project_id: @project.id, name: type_name)
          cached = ::Gitlab::Cache::Import::Caching.read_integer(cache_key, timeout: CACHE_TIMEOUT)
          return cached if cached.present?

          title = label_title(type_name)
          label = ::Labels::FindOrCreateService.new(
            nil, @project,
            title: title,
            color: ::Gitlab::Color.color_for(title).to_s,
            description: label_description
          ).execute(skip_authorization: true)

          return unless label

          ::Gitlab::Cache::Import::Caching.write(cache_key, label.id, timeout: CACHE_TIMEOUT)
          label.id
        end

        private

        def label_title(type_name)
          "#{_('imported')}:#{type_name}"
        end

        # This cannot be defined as a constant because translations are fetched in runtime
        def label_description
          _('Work items with this label were imported with a work item type name that ' \
            'could not be resolved in this namespace. They were assigned the default ' \
            'issue type instead.')
        end
      end
    end
  end
end
