require 'spec_helper'

describe GitHelper do
  describe '#short_sha' do
    let(:short_sha) { helper.short_sha('d4e043f6c20749a3ab3f4b8e23f2a8979f4b9100') }

    it { expect(short_sha).to eq('d4e043f6') }
  end
end
