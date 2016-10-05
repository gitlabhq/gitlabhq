require 'spec_helper'

describe TrendingProjectsFinder do
  let(:user) { create(:user) }
  let(:public_project1) { create(:empty_project, :public) }
  let(:public_project2) { create(:empty_project, :public) }
  let(:private_project) { create(:empty_project, :private) }
  let(:internal_project) { create(:empty_project, :internal) }

  before do
    3.times do
      create(:note_on_commit, project: public_project1)
    end

    2.times do
      create(:note_on_commit, project: public_project2, created_at: 5.weeks.ago)
    end

    create(:note_on_commit, project: private_project)
    create(:note_on_commit, project: internal_project)
  end

  describe '#execute', caching: true do
    context 'without an explicit time range' do
      it 'returns public trending projects' do
        projects = described_class.new.execute

        expect(projects).to eq([public_project1])
      end
    end

    context 'with an explicit time range' do
      it 'returns public trending projects' do
        projects = described_class.new.execute(2)

        expect(projects).to eq([public_project1, public_project2])
      end
    end

    it 'caches the list of projects' do
      projects = described_class.new

      expect(Project).to receive(:trending).once

      2.times { projects.execute }
    end
  end
end
