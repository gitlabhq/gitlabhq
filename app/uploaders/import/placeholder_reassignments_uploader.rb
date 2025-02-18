# frozen_string_literal: true

module Import
  class PlaceholderReassignmentsUploader < AttachmentUploader
    def mounted_as
      super || 'placeholder_reassignment_csv'
    end

    private

    def dynamic_segment
      File.join(model.class.underscore, model.id.to_s, mounted_as.to_s)
    end
  end
end
