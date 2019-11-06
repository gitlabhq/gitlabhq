# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      module NoteBase
        GREEN = '#38ae67'

        def color
          GREEN
        end

        def issue
          resource.noteable
        end

        def project
          issue.project
        end

        def project_link
          "[#{project.full_name}](#{project.web_url})"
        end

        def author
          resource.author
        end

        def author_profile_link
          "[#{author.to_reference}](#{url_for(author)})"
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
