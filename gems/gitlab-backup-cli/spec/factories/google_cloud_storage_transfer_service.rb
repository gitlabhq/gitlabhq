# frozen_string_literal: true

require "google/cloud/storage_transfer/v1"

FactoryBot.define do
  factory :google_cloud_storage_transfer_job, class: "Google::Cloud::StorageTransfer::V1::TransferJob" do
    name { "fake_transfer_job" }
    transfer_spec
  end

  factory :transfer_spec, class: "Google::Cloud::StorageTransfer::V1::TransferSpec" do
    gcs_data_sink
  end

  factory :gcs_data_sink, class: "Google::Cloud::StorageTransfer::V1::GcsData" do
    path { '/foo' }
  end
end
