# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Targets::Repositories do
  let(:context) { build_test_context }
  let(:gitaly_backup) { repo_target.gitaly_backup }

  subject(:repo_target) { described_class.new(context) }

  before do
    Gitlab::Backup::Cli::Models::Base.initialize_connection!(context: context)
  end

  describe '#dump' do
    it 'starts and finishes the gitaly_backup' do
      expect(gitaly_backup).to receive(:start).with(:create, '/path/to/destination')
      expect(repo_target).to receive(:enqueue_repositories)
      expect(gitaly_backup).to receive(:finish!)

      repo_target.dump('/path/to/destination')
    end
  end

  describe '#restore' do
    it 'starts and finishes the gitaly_backup' do
      expect(gitaly_backup).to receive(:start)
                                 .with(:restore, '/path/to/destination', remove_all_repositories: ["default"])
      expect(repo_target).to receive(:enqueue_repositories)
      expect(gitaly_backup).to receive(:finish!)
      expect(repo_target).to receive(:restore_object_pools)

      repo_target.restore('/path/to/destination')
    end
  end

  describe '#enqueue_repositories' do
    it 'calls each resource respective enqueue methods', :aggregate_failures do
      expect(repo_target).to receive(:enqueue_project_source_code)
      expect(repo_target).to receive(:enqueue_project_wiki)
      expect(repo_target).to receive(:enqueue_group_wiki)
      expect(repo_target).to receive(:enqueue_project_design_management)
      expect(repo_target).to receive(:enqueue_project_snippets)
      expect(repo_target).to receive(:enqueue_personal_snippets)

      repo_target.send(:enqueue_repositories)
    end
  end

  describe '#enqueue_project_source_code' do
    let(:resource) { Gitlab::Backup::Cli::Models::Project }
    let(:repository) { object_double(resource.new) }

    it 'enqueues project repository' do
      allow(resource).to receive(:find_each).and_yield(repository)

      expect(gitaly_backup).to receive(:enqueue).with(repository, always_create: true)

      repo_target.send(:enqueue_project_source_code)
    end
  end

  describe '#enqueue_project_wiki' do
    let(:resource) { Gitlab::Backup::Cli::Models::ProjectWiki }
    let(:repository) { object_double(resource.new) }

    it 'enqueues wiki repository' do
      allow(resource).to receive(:find_each).and_yield(repository)

      expect(gitaly_backup).to receive(:enqueue).with(repository)

      repo_target.send(:enqueue_project_wiki)
    end
  end

  describe '#enqueue_group_wiki' do
    let(:resource) { Gitlab::Backup::Cli::Models::GroupWiki }
    let(:repository) { object_double(resource.new) }

    it 'enqueues wiki repository' do
      allow(resource).to receive(:find_each).and_yield(repository)

      expect(gitaly_backup).to receive(:enqueue).with(repository)

      repo_target.send(:enqueue_group_wiki)
    end
  end

  describe '#enqueue_project_design_management' do
    let(:resource) { Gitlab::Backup::Cli::Models::ProjectDesignManagement }
    let(:repository) { object_double(resource.new) }

    it 'enqueues design management repository' do
      allow(resource).to receive(:find_each).and_yield(repository)

      expect(gitaly_backup).to receive(:enqueue).with(repository)

      repo_target.send(:enqueue_project_design_management)
    end
  end

  describe '#enqueue_project_snippets' do
    let(:resource) { Gitlab::Backup::Cli::Models::ProjectSnippet }
    let(:repository) { object_double(resource.new) }

    it 'enqueues the snippet' do
      allow(resource).to receive(:find_each).and_yield(repository)

      expect(gitaly_backup).to receive(:enqueue).with(repository)

      repo_target.send(:enqueue_project_snippets)
    end
  end

  describe '#enqueue_personal_snippets' do
    let(:resource) { Gitlab::Backup::Cli::Models::PersonalSnippet }
    let(:repository) { object_double(resource.new) }

    it 'enqueues the snippet' do
      allow(resource).to receive(:find_each).and_yield(repository)

      expect(gitaly_backup).to receive(:enqueue).with(repository)

      repo_target.send(:enqueue_personal_snippets)
    end
  end
end
