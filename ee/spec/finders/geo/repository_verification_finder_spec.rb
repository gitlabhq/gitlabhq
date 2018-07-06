require 'spec_helper'

describe Geo::RepositoryVerificationFinder, :postgresql do
  set(:project) { create(:project) }

  describe '#find_failed_repositories' do
    it 'returns projects where repository verification failed' do
      create(:repository_state, :repository_failed, :wiki_verified, project: project)

      expect(subject.find_failed_repositories(batch_size: 10))
        .to match_array(project)
    end

    it 'does not return projects where repository verification is outdated' do
      create(:repository_state, :repository_outdated, project: project)

      expect(subject.find_failed_repositories(batch_size: 10)).to be_empty
    end

    it 'does not return projects where repository verification is pending' do
      create(:repository_state, :wiki_verified, project: project)

      expect(subject.find_failed_repositories(batch_size: 10)).to be_empty
    end

    it 'returns projects ordered by next retry time' do
      next_project = create(:project)
      create(:repository_state, :repository_failed, repository_retry_at: 1.hour.from_now, project: project)
      create(:repository_state, :repository_failed, repository_retry_at: 30.minutes.from_now, project: next_project)

      expect(subject.find_failed_repositories(batch_size: 10)).to eq [next_project, project]
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')
        create(:repository_state, :repository_failed, project: project)
        create(:repository_state, :repository_failed, project: project_other_shard)

        expect(subject.find_failed_repositories(batch_size: 10))
          .to match_array(project)
      end
    end
  end

  describe '#find_failed_wikis' do
    it 'returns projects where wiki verification failed' do
      create(:repository_state, :repository_verified, :wiki_failed, project: project)

      expect(subject.find_failed_wikis(batch_size: 10))
        .to match_array(project)
    end

    it 'does not return projects where wiki verification is outdated' do
      create(:repository_state, :wiki_outdated, project: project)

      expect(subject.find_failed_wikis(batch_size: 10)).to be_empty
    end

    it 'does not return projects where wiki verification is pending' do
      create(:repository_state, :repository_verified, project: project)

      expect(subject.find_failed_wikis(batch_size: 10)).to be_empty
    end

    it 'returns projects ordered by next retry time' do
      next_project = create(:project)
      create(:repository_state, :wiki_failed, wiki_retry_at: 1.hour.from_now, project: project)
      create(:repository_state, :wiki_failed, wiki_retry_at: 30.minutes.from_now, project: next_project)

      expect(subject.find_failed_wikis(batch_size: 10)).to eq [next_project, project]
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')
        create(:repository_state, :wiki_failed, project: project)
        create(:repository_state, :wiki_failed, project: project_other_shard)

        expect(subject.find_failed_wikis(batch_size: 10))
          .to match_array(project)
      end
    end
  end

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

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')
        create(:repository_state, :repository_outdated, project: project)
        create(:repository_state, :repository_outdated, project: project_other_shard)

        expect(subject.find_outdated_projects(batch_size: 10))
          .to match_array(project)
      end
    end
  end

  describe '#find_unverified_projects' do
    it 'returns projects that never have been verified' do
      create(:repository_state, :repository_outdated)
      create(:repository_state, :wiki_outdated)

      expect(subject.find_unverified_projects(batch_size: 10))
        .to match_array(project)
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')

        expect(subject.find_unverified_projects(batch_size: 10))
          .to match_array(project)
      end
    end
  end
end
