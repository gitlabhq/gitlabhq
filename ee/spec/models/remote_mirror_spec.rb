require 'spec_helper'

describe RemoteMirror do
  let(:project) { create(:project, :repository, :remote_mirror) }

  describe '#sync' do
    let(:remote_mirror) { project.remote_mirrors.first }

    context 'as a Geo secondary' do
      it 'returns nil' do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)

        expect(remote_mirror.sync).to be_nil
      end
    end
  end
end
