require 'rake_helper'

describe 'gitlab:uploads:migrate rake tasks' do
  let!(:projects) { create_list(:project, 10, :with_avatar) }
  let(:model_class) { Project }
  let(:uploader_class) { AvatarUploader }
  let(:mounted_as) { :avatar }
  let(:batch_size) { 3 }

  before do
    stub_env('BATCH', batch_size.to_s)
    stub_uploads_object_storage(uploader_class)
    Rake.application.rake_require 'tasks/gitlab/uploads/migrate'

    allow(ObjectStorage::MigrateUploadsWorker).to receive(:perform_async)
  end

  def run
    args = [uploader_class.to_s, model_class.to_s, mounted_as].compact
    run_rake_task("gitlab:uploads:migrate", *args)
  end

  it 'enqueue jobs in batch' do
    expect(ObjectStorage::MigrateUploadsWorker).to receive(:enqueue!).exactly(4).times

    run
  end
end
