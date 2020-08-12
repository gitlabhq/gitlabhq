# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::MoveToProjectFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:no_access_project) { create(:project) }
  let(:guest_project) { create(:project) }
  let(:reporter_project) { create(:project, name: 'name') }
  let(:developer_project) { create(:project, name: 'name2') }
  let(:maintainer_project) { create(:project, name: 'name3') }

  describe '#execute' do
    context 'filter' do
      it 'does not return projects under Gitlab::Access::REPORTER' do
        guest_project.add_guest(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute).to be_empty
      end

      it 'returns projects equal or above Gitlab::Access::REPORTER' do
        reporter_project.add_reporter(user)
        developer_project.add_developer(user)
        maintainer_project.add_maintainer(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to contain_exactly(reporter_project, developer_project, maintainer_project)
      end

      it 'does not include the source project' do
        project.add_reporter(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to be_empty
      end

      it 'does not return archived projects' do
        reporter_project.add_reporter(user)
        ::Projects::UpdateService.new(reporter_project, user, archived: true).execute
        other_reporter_project = create(:project)
        other_reporter_project.add_reporter(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to eq([other_reporter_project])
      end

      it 'does not return projects for which issues are disabled' do
        reporter_project.add_reporter(user)
        reporter_project.update!(issues_enabled: false)
        other_reporter_project = create(:project)
        other_reporter_project.add_reporter(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to eq([other_reporter_project])
      end

      it 'returns a page of projects ordered by star count' do
        stub_const('Autocomplete::MoveToProjectFinder::LIMIT', 2)

        projects = [
          create(:project, namespace: user.namespace, star_count: 1),
          create(:project, namespace: user.namespace, star_count: 5),
          create(:project, namespace: user.namespace)
        ]

        finder = described_class.new(user, project_id: project.id)
        page = finder.execute.to_a

        expect(page.length).to eq(2)
        expect(page).to eq([projects[1], projects[0]])
      end
    end

    context 'search' do
      it 'returns projects matching a search query' do
        foo_project = create(:project, name: 'foo')
        foo_project.add_maintainer(user)

        wadus_project = create(:project, name: 'wadus')
        wadus_project.add_maintainer(user)

        expect(described_class.new(user, project_id: project.id).execute.to_a)
          .to contain_exactly(foo_project, wadus_project)

        expect(described_class.new(user, project_id: project.id, search: 'wadus').execute.to_a)
          .to contain_exactly(wadus_project)
      end

      it 'allows searching by parent namespace' do
        group = create(:group)
        other_project = create(:project, group: group)
        other_project.add_maintainer(user)

        expect(described_class.new(user, project_id: project.id, search: group.name).execute.to_a)
          .to contain_exactly(other_project)
      end
    end
  end
end
