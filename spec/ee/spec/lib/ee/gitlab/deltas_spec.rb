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

    it 'handles annotated tags on an object' do
      object_id = 'faaf198af3a36dbf41961466703cc1d47c61d051'
      options = { message: 'test tag message\n',
                  tagger: { name: 'John Smith', email: 'john@gmail.com' } }
      result = project.repository.rugged.tags.create('annotated-tag', object_id, options)

      change = {
        oldrev: result.annotation.oid,
        newrev: TestEnv::BRANCH_SHA['master']
      }

      expect(described_class.delta_size_check(change, project.repository)).to eq(0)
    end
  end
end
