# frozen_string_literal: true

module QA
  module Vendor
    module Smocker
      class EventPayload
        def initialize(hook_data)
          @hook_data = hook_data
        end

        def raw
          @hook_data
        end

        def event
          raw[:object_kind]&.to_sym
        end

        def event_name
          raw[:event_name]&.to_sym
        end

        def project_name
          raw.dig(:project, :name)
        end

        def mr?
          event == :merge_request
        end

        def issue?
          event == :issue
        end

        def note?
          event == :note
        end

        def push?
          event == :push
        end

        def tag?
          event == :tag_push
        end

        def wiki?
          event == :wiki_page
        end

        def subgroup_create?
          event_name == :subgroup_create
        end

        def subgroup_destroy?
          event_name == :subgroup_destroy
        end
      end
    end
  end
end
