# frozen_string_literal: true

module QA
  module Page
    module Group
      class Members < Page::Base
        include Page::Component::Members::InviteMembersModal
        include Page::Component::Members::MembersTable
        include Page::Component::Placeholders::PlaceholdersTable

        def find_tab(tab_name)
          find('a[role="tab"]', text: tab_name)
        end

        def has_tab?(tab_name)
          find_tab(tab_name)
        end

        def has_tab_count?(tab_name, expected_count)
          has_tab?(tab_name)
          find_tab(tab_name).text.split("\n")[1].to_i == expected_count
        end

        def click_tab(tab_name)
          find_tab(tab_name).click
        end
      end
    end
  end
end

QA::Page::Group::Members.prepend_mod_with('Page::Component::DuoChatCallout', namespace: QA)
