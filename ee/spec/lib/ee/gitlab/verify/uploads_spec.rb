require 'spec_helper'

describe Gitlab::Verify::Uploads do
  before do
    stub_uploads_object_storage(AvatarUploader)
  end

  it 'includes uploads in object storage' do
    local_failure = create(:upload)
    remote_failure = create(:upload, :object_storage)

    failures = {}
    described_class.new(batch_size: 10).run_batches { |_, failed| failures.merge!(failed) }

    expect(failures.keys).to contain_exactly(local_failure, remote_failure)
  end
end
