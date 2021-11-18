# frozen_string_literal: true

module Issues
  class SetCrmContactsService < ::BaseProjectService
    attr_accessor :issue, :errors

    MAX_ADDITIONAL_CONTACTS = 6

    def execute(issue)
      @issue = issue
      @errors = []

      return error_no_permissions unless allowed?
      return error_invalid_params unless valid_params?

      determine_changes if params[:crm_contact_ids]

      return error_too_many if too_many?

      add_contacts if params[:add_crm_contact_ids]
      remove_contacts if params[:remove_crm_contact_ids]

      if issue.valid?
        ServiceResponse.success(payload: issue)
      else
        # The default error isn't very helpful: "Issue customer relations contacts is invalid"
        issue.errors.delete(:issue_customer_relations_contacts)
        issue.errors.add(:issue_customer_relations_contacts, errors.to_sentence)
        ServiceResponse.error(payload: issue, message: issue.errors.full_messages)
      end
    end

    private

    def determine_changes
      existing_contact_ids = issue.issue_customer_relations_contacts.map(&:contact_id)
      params[:add_crm_contact_ids] = params[:crm_contact_ids] - existing_contact_ids
      params[:remove_crm_contact_ids] = existing_contact_ids - params[:crm_contact_ids]
    end

    def add_contacts
      params[:add_crm_contact_ids].uniq.each do |contact_id|
        issue_contact = issue.issue_customer_relations_contacts.create(contact_id: contact_id)

        unless issue_contact.persisted?
          # The validation ensures that the id exists and the user has permission
          errors << "#{contact_id}: The resource that you are attempting to access does not exist or you don't have permission to perform this action"
        end
      end
    end

    def remove_contacts
      issue.issue_customer_relations_contacts
        .where(contact_id: params[:remove_crm_contact_ids]) # rubocop: disable CodeReuse/ActiveRecord
        .delete_all
    end

    def allowed?
      current_user&.can?(:set_issue_crm_contacts, issue)
    end

    def valid_params?
      set_present? ^ add_or_remove_present?
    end

    def set_present?
      params[:crm_contact_ids].present?
    end

    def add_or_remove_present?
      params[:add_crm_contact_ids].present? || params[:remove_crm_contact_ids].present?
    end

    def too_many?
      params[:add_crm_contact_ids] && params[:add_crm_contact_ids].length > MAX_ADDITIONAL_CONTACTS
    end

    def error_no_permissions
      ServiceResponse.error(message: ['You have insufficient permissions to set customer relations contacts for this issue'])
    end

    def error_invalid_params
      ServiceResponse.error(message: ['You cannot combine crm_contact_ids with add_crm_contact_ids or remove_crm_contact_ids'])
    end

    def error_too_many
      ServiceResponse.error(payload: issue, message: ["You can only add up to #{MAX_ADDITIONAL_CONTACTS} contacts at one time"])
    end
  end
end
