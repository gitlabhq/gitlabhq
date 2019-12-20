# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      module NoteBase
        GREEN = '#38ae67'

        def color(_)
          GREEN
        end

        def issue
          resource.noteable
        end

        def project
          issue.project
        end

        def author
          resource.author
        end

        def fields
          [
            {
              title: 'Comment',
              value: resource.note
            }
          ]
        end

        private

        attr_reader :resource
      end
    end
  end
end
