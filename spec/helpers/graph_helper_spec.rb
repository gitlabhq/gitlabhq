require 'spec_helper'

describe GraphHelper do
  describe '#get_refs' do
    let(:project) { create(:project) }
    let(:commit)  { project.commit("master") }
    let(:graph) { Network::Graph.new(project, 'master', commit, '') }

    it 'filter our refs used by GitLab' do
      allow(commit).to receive(:ref_names).and_return(['refs/merge-requests/abc', 'master', 'refs/tmp/xyz'])
      self.instance_variable_set(:@graph, graph)
      refs = get_refs(project.repository, commit)
      expect(refs).to eq('master')
    end
  end
end
