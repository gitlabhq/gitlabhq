require 'spec_helper'

describe EE::Gitlab::Deltas do
  let(:project) { create(:project, :repository) }

  describe '.delta_size_check' do
    it 'returns a non-zero file size' do
      change = {
        oldrev: TestEnv::BRANCH_SHA['feature'],
        newrev: TestEnv::BRANCH_SHA['master']
      }

      expect(described_class.delta_size_check(change, project.repository)).to be > 0
    end
  end
end
