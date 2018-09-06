# frozen_string_literal: true

module EE
  module AutocompleteController
    def project_groups
      groups = ::Autocomplete::ProjectInvitedGroupsFinder
        .new(current_user, params)
        .execute

      render json: InvitedGroupSerializer.new.represent(groups)
    end
  end
end
