require 'spec_helper'

describe Geo::RepositoryVerificationFinder, :postgresql do
  set(:project) { create(:project) }

  describe '#find_outdated_projects' do
    it 'returns projects where repository verification is outdated' do
      create(:repository_state, :repository_outdated, project: project)

      expect(subject.find_outdated_projects(batch_size: 10))
        .to match_array(project)
    end

    it 'returns projects where repository verification is pending' do
      create(:repository_state, :wiki_verified, project: project)

      expect(subject.find_outdated_projects(batch_size: 10))
        .to match_array(project)
    end

    it 'returns projects where wiki verification is outdated' do
      create(:repository_state, :wiki_outdated, project: project)

      expect(subject.find_outdated_projects(batch_size: 10))
        .to match_array(project)
    end

    it 'returns projects where wiki verification is pending' do
      create(:repository_state, :repository_verified, project: project)

      expect(subject.find_outdated_projects(batch_size: 10))
        .to match_array(project)
    end
  end

  describe '#find_unverified_projects' do
    it 'returns projects that never have been verified' do
      expect(subject.find_unverified_projects(batch_size: 10))
        .to match_array(project)
    end
  end
end
