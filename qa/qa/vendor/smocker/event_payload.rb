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
          event == :tag
        end

        def wiki?
          event == :wiki_page
        end
      end
    end
  end
end
