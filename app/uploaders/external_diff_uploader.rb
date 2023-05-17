# frozen_string_literal: true

class ExternalDiffUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_location :external_diffs

  alias_method :upload, :model

  def filename
    "diff-#{model.id}"
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    File.join(model.model_name.plural, "mr-#{model.merge_request_id}")
  end
end
