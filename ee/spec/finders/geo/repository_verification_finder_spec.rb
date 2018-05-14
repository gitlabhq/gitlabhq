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

    it 'does not return projects where repository verification failed' do
      create(:repository_state, :repository_failed, :wiki_verified, project: project)

      expect(subject.find_outdated_projects(batch_size: 10)).to be_empty
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

    it 'does not return projects where wiki verification failed' do
      create(:repository_state, :repository_verified, :wiki_failed, project: project)

      expect(subject.find_outdated_projects(batch_size: 10)).to be_empty
    end

    it 'returns less active projects first' do
      less_active_project = create(:project)
      create(:repository_state, :repository_outdated, project: project)
      create(:repository_state, :repository_outdated, project: less_active_project)
      project.update_column(:last_repository_updated_at, 30.minutes.ago)
      less_active_project.update_column(:last_repository_updated_at, 2.days.ago)

      expect(subject.find_outdated_projects(batch_size: 10)).to eq [less_active_project, project]
    end
  end

  describe '#find_unverified_projects' do
    it 'returns projects that never have been verified' do
      expect(subject.find_unverified_projects(batch_size: 10))
        .to match_array(project)
    end
  end
end
