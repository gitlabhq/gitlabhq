# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Index < Page::Base
          view 'app/views/projects/issues/_issue.html.haml' do
            element :issue_link, 'link_to issue.title' # rubocop:disable QA/ElementWithPattern
          end

          def click_issue_link(title)
            click_link(title)
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Index.prepend_if_ee('QA::EE::Page::Project::Issue::Index')
