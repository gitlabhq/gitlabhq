# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Targets::Repositories do
  let(:context) { Gitlab::Backup::Cli::Context.build }
  let(:strategy) { repo_target.strategy }

  subject(:repo_target) { described_class.new(context) }

  describe '#dump' do
    it 'starts and finishes the strategy' do
      expect(strategy).to receive(:start).with(:create, '/path/to/destination')
      expect(repo_target).to receive(:enqueue_consecutive)
      expect(strategy).to receive(:finish!)

      repo_target.dump('/path/to/destination')
    end
  end

  describe '#restore' do
    it 'starts and finishes the strategy' do
      expect(strategy).to receive(:start).with(:restore, '/path/to/destination', remove_all_repositories: ["default"])
      expect(repo_target).to receive(:enqueue_consecutive)
      expect(strategy).to receive(:finish!)
      expect(repo_target).to receive(:restore_object_pools)

      repo_target.restore('/path/to/destination')
    end
  end

  describe '#enqueue_consecutive' do
    it 'calls enqueue_consecutive_projects and enqueue_consecutive_snippets' do
      expect(repo_target).to receive(:enqueue_consecutive_projects)
      expect(repo_target).to receive(:enqueue_consecutive_snippets)

      repo_target.send(:enqueue_consecutive)
    end
  end

  describe '#enqueue_project' do
    let(:project) { instance_double('Project', design_management_repository: nil) }

    it 'enqueues project and wiki' do
      expect(strategy).to receive(:enqueue).with(project, Gitlab::Backup::Cli::RepoType::PROJECT)
      expect(strategy).to receive(:enqueue).with(project, Gitlab::Backup::Cli::RepoType::WIKI)

      repo_target.send(:enqueue_project, project)
    end

    context 'when project has design management repository' do
      let(:design_repo) { instance_double('DesignRepository') }
      let(:project) { instance_double('Project', design_management_repository: design_repo) }

      it 'enqueues project, wiki, and design' do
        expect(strategy).to receive(:enqueue).with(project, Gitlab::Backup::Cli::RepoType::PROJECT)
        expect(strategy).to receive(:enqueue).with(project, Gitlab::Backup::Cli::RepoType::WIKI)
        expect(strategy).to receive(:enqueue).with(design_repo, Gitlab::Backup::Cli::RepoType::DESIGN)

        repo_target.send(:enqueue_project, project)
      end
    end
  end

  describe '#enqueue_snippet' do
    let(:snippet) { instance_double('Snippet') }

    it 'enqueues the snippet' do
      expect(strategy).to receive(:enqueue).with(snippet, Gitlab::Backup::Cli::RepoType::SNIPPET)

      repo_target.send(:enqueue_snippet, snippet)
    end
  end
end
