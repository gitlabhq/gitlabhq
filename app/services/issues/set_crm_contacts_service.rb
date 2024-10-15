# frozen_string_literal: true

module Issues
  class SetCrmContactsService < ::BaseContainerService
    MAX_ADDITIONAL_CONTACTS = 6

    # Replacing contacts by email is not currently supported
    def execute(issue)
      @issue = issue
      @errors = []

      return error_no_permissions unless allowed?
      return error_invalid_params unless valid_params?

      @existing_ids = issue.customer_relations_contact_ids
      determine_changes if set_present?
      return error_too_many if too_many?

      @added_count = 0
      @removed_count = 0

      add if params[:add_ids].present?
      remove if params[:remove_ids].present?

      add_by_email if params[:add_emails].present?
      remove_by_email if params[:remove_emails].present?

      if issue.valid?
        GraphqlTriggers.issue_crm_contacts_updated(issue)
        issue.touch
        create_system_note
        ServiceResponse.success(payload: issue)
      else
        # The default error isn't very helpful: "Issue customer relations contacts is invalid"
        issue.errors.delete(:issue_customer_relations_contacts)
        issue.errors.add(:issue_customer_relations_contacts, errors.to_sentence)
        ServiceResponse.error(payload: issue, message: issue.errors.full_messages.to_sentence)
      end
    end

    private

    attr_accessor :issue, :errors, :existing_ids, :added_count, :removed_count

    def determine_changes
      params[:add_ids] = params[:replace_ids] - existing_ids
      params[:remove_ids] = existing_ids - params[:replace_ids]
    end

    def add
      add_by_id(params[:add_ids])
    end

    def add_by_email
      contact_ids = ::CustomerRelations::Contact.find_ids_by_emails(container.crm_group, emails(:add_emails))
      add_by_id(contact_ids)
    end

    def emails(key)
      params[key].map do |email|
        extract_email_from_request_param(email)
      end
    end

    def add_by_id(contact_ids)
      contact_ids -= existing_ids
      contact_ids.uniq.each do |contact_id|
        issue_contact = issue.issue_customer_relations_contacts.create(contact_id: contact_id)

        if issue_contact.persisted?
          @added_count += 1
        else
          # The validation ensures that the id exists and the user has permission
          errors << "#{contact_id}: The resource that you are attempting to access does not exist or you don't have permission to perform this action"
        end
      end
    end

    def remove
      remove_by_id(params[:remove_ids])
    end

    def remove_by_email
      contact_ids = ::CustomerRelations::IssueContact.find_contact_ids_by_emails(issue.id, emails(:remove_emails))
      remove_by_id(contact_ids)
    end

    def remove_by_id(contact_ids)
      contact_ids &= existing_ids
      @removed_count += issue.issue_customer_relations_contacts
        .where(contact_id: contact_ids) # rubocop: disable CodeReuse/ActiveRecord
        .delete_all
    end

    def extract_email_from_request_param(email_param)
      email_param.delete_prefix(::CustomerRelations::Contact.reference_prefix_quoted)
                 .delete_prefix(::CustomerRelations::Contact.reference_prefix)
                 .delete_suffix(::CustomerRelations::Contact.reference_postfix)
                 .tr('"', '')
    end

    def allowed?
      current_user&.can?(:set_issue_crm_contacts, issue)
    end

    def valid_params?
      set_present? ^ add_or_remove_present?
    end

    def set_present?
      !params[:replace_ids].nil?
    end

    def add_or_remove_present?
      add_present? || remove_present?
    end

    def add_present?
      params[:add_ids].present? || params[:add_emails].present?
    end

    def remove_present?
      params[:remove_ids].present? || params[:remove_emails].present?
    end

    def too_many?
      too_many_ids? || too_many_emails?
    end

    def too_many_ids?
      params[:add_ids] && params[:add_ids].length > MAX_ADDITIONAL_CONTACTS
    end

    def too_many_emails?
      params[:add_emails] && params[:add_emails].length > MAX_ADDITIONAL_CONTACTS
    end

    def create_system_note
      SystemNoteService.change_issuable_contacts(
        issue, issue.project, current_user, added_count, removed_count)
    end

    def error_no_permissions
      ServiceResponse.error(message: _('You have insufficient permissions to set customer relations contacts for this issue'))
    end

    def error_invalid_params
      ServiceResponse.error(message: _('You cannot combine replace_ids with add_ids or remove_ids'))
    end

    def error_too_many
      ServiceResponse.error(payload: issue, message: _("You can only add up to %{max_contacts} contacts at one time" % { max_contacts: MAX_ADDITIONAL_CONTACTS }))
    end
  end
end
