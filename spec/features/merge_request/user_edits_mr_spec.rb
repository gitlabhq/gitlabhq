require 'rails_helper'

describe 'Merge request > User edits MR' do
  include ProjectForksHelper

  it_behaves_like 'an editable merge request'

  context 'for a forked project' do
    it_behaves_like 'an editable merge request' do
      let(:source_project) { fork_project(target_project, nil, repository: true) }
    end
  end
end
