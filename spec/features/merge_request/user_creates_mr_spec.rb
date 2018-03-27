require 'rails_helper'

describe 'Merge request > User creates MR' do
  it_behaves_like 'a creatable merge request'

  context 'from a forked project' do
    include ProjectForksHelper

    let(:canonical_project) { create(:project, :public, :repository) }

    let(:source_project) do
      fork_project(canonical_project, user,
        repository: true,
        namespace: user.namespace)
    end

    context 'to canonical project' do
      it_behaves_like 'a creatable merge request'
    end

    context 'to another forked project' do
      let(:target_project) do
        fork_project(canonical_project, user,
          repository: true,
          namespace: user.namespace)
      end

      it_behaves_like 'a creatable merge request'
    end
  end
end
