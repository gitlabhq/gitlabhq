# frozen_string_literal: true

class AttachmentUploader < GitlabUploader
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads
  include UploaderHelper

  def mounted_as
    # Geo fails to sync attachments on Note, and LegacyDiffNotes with missing mount_point.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/209752 for more details.
    if model.class.underscore.include?('note')
      super || 'attachment'
    else
      super
    end
  end

  private

  def dynamic_segment
    File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
  end
end
