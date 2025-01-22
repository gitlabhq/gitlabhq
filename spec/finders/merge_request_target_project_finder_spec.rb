# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestTargetProjectFinder do
  include ProjectForksHelper

  let(:user) { create(:user) }

  subject(:finder) { described_class.new(current_user: user, source_project: forked_project) }

  shared_examples 'finding related projects' do
    it 'finds sibling projects and base project' do
      other_fork

      expect(finder.execute).to contain_exactly(base_project, other_fork, forked_project)
    end

    it 'does not include projects that have merge requests turned off by default' do
      other_fork.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
      base_project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)

      expect(finder.execute).to contain_exactly(forked_project)
    end

    it 'includes projects that have merge requests turned off by default with a more-permissive project feature' do
      finder = described_class.new(current_user: user, source_project: forked_project, project_feature: :repository)

      other_fork.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
      base_project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)

      expect(finder.execute).to contain_exactly(base_project, other_fork, forked_project)
    end

    it 'does not contain archived projects' do
      base_project.update!(archived: true)

      expect(finder.execute).to contain_exactly(other_fork, forked_project)
    end

    it 'does not include routes by default' do
      row = finder.execute.first

      expect(row.association(:route).loaded?).to be_falsey
      expect(row.association(:namespace).loaded?).to be_falsey
      expect(row.namespace.association(:route).loaded?).to be_falsey
    end

    it 'includes routes when requested' do
      row = finder.execute(include_routes: true).first

      expect(row.association(:route).loaded?).to be_truthy
      expect(row.association(:namespace).loaded?).to be_truthy
      expect(row.namespace.association(:route).loaded?).to be_truthy
    end
  end

  context 'public projects' do
    let(:base_project) { create(:project, :public, path: 'base') }
    let(:forked_project) { fork_project(base_project) }
    let(:other_fork) { fork_project(base_project) }

    it_behaves_like 'finding related projects'
  end

  context 'private projects' do
    let(:base_project) { create(:project, :private, path: 'base') }
    let(:forked_project) { fork_project(base_project, base_project.first_owner) }
    let(:other_fork) { fork_project(base_project, base_project.first_owner) }

    context 'when the user is a member of all projects' do
      before do
        base_project.add_developer(user)
        forked_project.add_developer(user)
        other_fork.add_developer(user)
      end

      it_behaves_like 'finding related projects'
    end

    it 'only finds the projects the user is a member of' do
      other_fork.add_developer(user)
      base_project.add_developer(user)

      expect(finder.execute).to contain_exactly(other_fork, base_project)
    end
  end

  context 'searching' do
    let(:base_project) { create(:project, :private, path: 'base') }
    let(:forked_project) { fork_project(base_project, base_project.first_owner) }
    let(:other_fork) { fork_project(base_project) }

    before do
      base_project.add_developer(user)
      forked_project.add_developer(user)
      other_fork.add_developer(user)
    end

    it 'returns all projects with empty search' do
      expect(finder.execute(search: '')).to match_array([base_project, forked_project, other_fork])
    end

    it 'returns forked project with search string' do
      expect(finder.execute(search: forked_project.full_path)).to match_array([forked_project])
    end

    it 'returns no projects with search for project that does no exist' do
      expect(finder.execute(search: 'root')).to be_empty
    end
  end
end
