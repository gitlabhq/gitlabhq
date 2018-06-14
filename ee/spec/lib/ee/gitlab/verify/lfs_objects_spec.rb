require 'spec_helper'

describe Gitlab::Verify::LfsObjects do
  before do
    stub_lfs_object_storage
  end

  it 'includes LFS objects in object storage' do
    local_failure = create(:lfs_object)
    remote_failure = create(:lfs_object, :object_storage)

    failures = {}
    described_class.new(batch_size: 10).run_batches { |_, failed| failures.merge!(failed) }

    expect(failures.keys).to contain_exactly(local_failure, remote_failure)
  end
end
