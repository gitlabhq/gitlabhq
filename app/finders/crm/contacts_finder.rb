# frozen_string_literal: true

# Finder for retrieving contacts scoped to a group
#
# Arguments:
#   current_user - user performing the action. Must have the correct permission level for the group.
#   params:
#     group: Group, required
module Crm
  class ContactsFinder
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    attr_reader :params, :current_user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return CustomerRelations::Contact.none unless root_group

      root_group.contacts
    end

    private

    def root_group
      strong_memoize(:root_group) do
        group = params[:group]&.root_ancestor

        next unless can?(@current_user, :read_crm_contact, group)

        group
      end
    end
  end
end
