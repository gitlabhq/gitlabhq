require 'spec_helper'

describe Autocomplete::MoveToProjectFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

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

      it 'returns projects equal or above Gitlab::Access::REPORTER ordered by name' do
        reporter_project.add_reporter(user)
        developer_project.add_developer(user)
        maintainer_project.add_maintainer(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to eq([reporter_project, developer_project, maintainer_project])
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
        reporter_project.update(issues_enabled: false)
        other_reporter_project = create(:project)
        other_reporter_project.add_reporter(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to eq([other_reporter_project])
      end

      it 'returns a page of projects ordered by name' do
        stub_const('Autocomplete::MoveToProjectFinder::LIMIT', 2)

        projects = create_list(:project, 3) do |project|
          project.add_developer(user)
        end

        finder = described_class.new(user, project_id: project.id)
        page = finder.execute.to_a

        expected_projects = projects.sort_by(&:name).first(2)
        expect(page.length).to eq(2)
        expect(page).to eq(expected_projects)
      end
    end

    context 'search' do
      it 'returns projects matching a search query' do
        foo_project = create(:project, name: 'foo')
        foo_project.add_maintainer(user)

        wadus_project = create(:project, name: 'wadus')
        wadus_project.add_maintainer(user)

        expect(described_class.new(user, project_id: project.id).execute.to_a)
          .to eq([foo_project, wadus_project])

        expect(described_class.new(user, project_id: project.id, search: 'wadus').execute.to_a)
          .to eq([wadus_project])
      end
    end
  end
end
