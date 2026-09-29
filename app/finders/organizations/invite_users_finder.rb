# frozen_string_literal: true

# Used for searching users that can be invited to an organization, i.e. active
# users who are not already members of it.
#
# Arguments:
#   organization - the Organizations::Organization users would be invited to
#   current_user - the user performing the search
#   search: string
module Organizations
  class InviteUsersFinder < UsersFinder
    def initialize(organization:, current_user:, search: nil)
      @organization = organization

      super(current_user, { search: search })
    end

    private

    attr_reader :organization

    def base_scope
      super
        .active
        .without_project_bot
        .not_member_of_organization(organization)
    end
  end
end
