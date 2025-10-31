# frozen_string_literal: true

# currently included in Note, Snippet, AntiAbuse::Reports::Note
# via Issuable: Issue, MergeRequest
module Editable
  extend ActiveSupport::Concern

  def edited?
    last_edited_at.present? && last_edited_at != created_at
  end

  def last_edited_by
    return unless edited?

    super || editable_ghost_author
  end

  private

  def editable_ghost_author
    @editable_ghost_author ||= if respond_to?(:organization_id)
                                 Users::Internal.for_organization(organization_id).ghost
                               elsif author.present?
                                 Users::Internal.for_organization(author.organization_id).ghost
                               else
                                 Gitlab::AppLogger.warn(
                                   "Fallback ghost user used for Editable #{self.class.name}=#{id}"
                                 )
                                 Users::Internal.for_organization(Organizations::Organization.first).ghost # rubocop:disable Gitlab/PreventOrganizationFirst -- final fallback after all other methods fail
                               end
  end
end
