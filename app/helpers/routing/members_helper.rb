# frozen_string_literal: true

module Routing
  module MembersHelper
    def source_members_url(member)
      case member.source_type
      when 'Namespace'
        group_group_members_url(member.source)
      when 'Project'
        project_project_members_url(member.source)
      end
    end
  end
end
