# frozen_string_literal: true

module QA
  module Page
    module Project
      class Members < Page::Base
        include Page::Component::Members::InviteMembersModal
        include Page::Component::Members::MembersTable
      end
    end
  end
end

QA::Page::Project::Members.prepend_mod_with('Page::Component::DuoChatCallout', namespace: QA)
