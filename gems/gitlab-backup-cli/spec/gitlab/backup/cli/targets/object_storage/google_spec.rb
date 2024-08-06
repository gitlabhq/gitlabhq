# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Targets::ObjectStorage::Google do
  let(:gitlab_config) { class_double("GitlabSettings::Settings") }
  let(:supported_object_store) do
    instance_double(
      "GitlabSettings::Options",
      enabled: true,
      connection: instance_double("GitlabSettings::Options", provider: "Google")
    )
  end

  let(:supported_config) { instance_double("GitlabSettings::Options", object_store: supported_object_store) }
  let(:client) { instance_double("::Google::Cloud::StorageTransfer::V1::StorageTransferService::Client") }
  let(:existing_transfer_job) { build(:google_cloud_storage_transfer_job) }
  let(:new_transfer_job_spec) do
    {
      name: "transferJobs/fake_object-backup",
      project_id: "fake_project",
      transfer_spec: {
        gcs_data_source: {
          bucket_name: "fake_source_bucket"
        },
        gcs_data_sink: {
          bucket_name: "fake_backup_bucket",
          path: "backups/12345/fake_object/"
        }
      },
      status: :ENABLED
    }
  end

  let(:backup_options) { instance_double("Gitlab::Backup::Options", remote_directory: 'fake_backup_bucket') }

  before do
    allow(Gitlab).to receive(:config).and_return(gitlab_config)
    allow(::Google::Cloud::StorageTransfer).to receive(:storage_transfer_service).and_return(client)
  end

  subject(:object_storage) { described_class.new("fake_object", backup_options, supported_config) }

  describe "#dump" do
    let(:supported_provider) do
      instance_double(
        "GitlabSettings::Options", provider: "Google", google_application_default: true, google_project: "fake_project"
      )
    end

    let(:supported_object_store) do
      instance_double(
        "GitlabSettings::Options", enabled: true, connection: supported_provider, remote_directory: "fake_source_bucket"
      )
    end

    let(:supported_config) { instance_double("GitlabSettings::Options", object_store: supported_object_store) }

    before do
      allow(gitlab_config).to receive(:[]).with('fake_object').and_return(supported_config)
    end

    context "when job exists" do
      before do
        allow(client).to receive(:get_transfer_job).and_return(existing_transfer_job)
      end

      it "reuses existing job" do
        updated_spec = new_transfer_job_spec
        expect(client).to receive(:update_transfer_job).with(
          job_name: updated_spec[:name],
          project_id: updated_spec.delete(:project_id),
          transfer_job: updated_spec
        )
        expect(client).to receive(:run_transfer_job).with({ job_name: "fake_transfer_job", project_id: "fake_project" })
        object_storage.dump(nil, 12345)
      end
    end

    context "when job does not exist" do
      before do
        allow(client).to receive(:get_transfer_job).with(
          job_name: "transferJobs/fake_object-backup", project_id: "fake_project"
        ).and_raise(::Google::Cloud::NotFoundError)
        allow(client).to receive(:run_transfer_job)
      end

      it "creates a new job" do
        expect(client).to receive(:create_transfer_job)
          .with(transfer_job: new_transfer_job_spec).and_return(existing_transfer_job)
        object_storage.dump(nil, 12345)
      end
    end
  end
end
