# frozen_string_literal: true

# Finder for retrieving contacts scoped to a group
#
# Arguments:
#   current_user - user performing the action. Must have the correct permission level for the group.
#   params:
#     group: Group, required
#     search: String, optional
#     state: CustomerRelations::ContactStateEnum, optional
#     ids: int[], optional
module Crm
  class ContactsFinder
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    attr_reader :params, :current_user

    def self.counts_by_state(current_user, params = {})
      params = params.merge(sort: nil)
      new(current_user, params).execute.counts_by_state
    end

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      group = params[:group]&.crm_group
      return CustomerRelations::Contact.none unless group && can?(@current_user, :read_crm_contact, group)

      contacts = group.contacts
      contacts = by_ids(contacts)
      contacts = by_state(contacts)
      contacts = by_search(contacts)
      sort_contacts(contacts)
    end

    private

    def sort_contacts(contacts)
      return contacts.sort_by_name unless @params.key?(:sort)
      return contacts if @params[:sort].nil?

      field = @params[:sort][:field]
      direction = @params[:sort][:direction]

      if field == 'organization'
        contacts.sort_by_organization(direction)
      else
        contacts.sort_by_field(field, direction)
      end
    end

    def by_search(contacts)
      return contacts unless search?

      contacts.search(params[:search])
    end

    def by_state(contacts)
      return contacts unless state?

      contacts.search_by_state(params[:state])
    end

    def by_ids(contacts)
      return contacts unless ids?

      contacts.id_in(params[:ids])
    end

    def search?
      params[:search].present?
    end

    def state?
      params[:state].present?
    end

    def ids?
      params[:ids].present?
    end
  end
end
