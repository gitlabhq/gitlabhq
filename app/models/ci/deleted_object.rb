# frozen_string_literal: true

module Ci
  class DeletedObject < Ci::ApplicationRecord
    mount_uploader :file, DeletedObjectUploader

    scope :ready_for_destruction, ->(limit) do
      where('pick_up_at < ?', Time.current).limit(limit)
    end

    scope :lock_for_destruction, ->(limit) do
      ready_for_destruction(limit)
        .select(:id)
        .order(:pick_up_at)
        .lock('FOR UPDATE SKIP LOCKED')
    end

    validates :project_id, presence: true, on: :create

    def self.bulk_import(artifacts, pick_up_at = nil)
      attributes = artifacts.each.with_object([]) do |artifact, accumulator|
        record = artifact.to_deleted_object_attrs(pick_up_at)
        accumulator << record if record[:store_dir] && record[:file]
      end

      insert_all(attributes) if attributes.any?
    end

    def delete_file_from_storage
      file.remove!
      true
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
      false
    end
  end
end
