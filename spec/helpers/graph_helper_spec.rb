# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphHelper do
  describe '#get_refs' do
    let(:project) { create(:project, :repository) }
    let(:commit)  { project.commit("master") }
    let(:graph) { Network::Graph.new(project, 'master', commit, '') }

    it 'filters our refs used by GitLab' do
      self.instance_variable_set(:@graph, graph)
      refs = refs(project.repository, commit)

      expect(refs).to match('master')
    end
  end

  describe '#should_render_dora_charts' do
    let(:project) { create(:project, :private) }

    before do
      self.instance_variable_set(:@project, project)
    end

    it 'always returns false' do
      expect(should_render_dora_charts).to be(false)
    end
  end

  describe '#should_render_quality_summary' do
    let(:project) { create(:project, :private) }

    before do
      self.instance_variable_set(:@project, project)
    end

    it 'always returns false' do
      expect(should_render_quality_summary).to be(false)
    end
  end
end
