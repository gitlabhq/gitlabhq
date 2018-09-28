require 'spec_helper'

describe Autocomplete::MoveToProjectFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:no_access_project) { create(:project) }
  let(:guest_project) { create(:project) }
  let(:reporter_project) { create(:project) }
  let(:developer_project) { create(:project) }
  let(:maintainer_project) { create(:project) }

  describe '#execute' do
    context 'filter' do
      it 'does not return projects under Gitlab::Access::REPORTER' do
        guest_project.add_guest(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute).to be_empty
      end

      it 'returns projects equal or above Gitlab::Access::REPORTER ordered by id in descending order' do
        reporter_project.add_reporter(user)
        developer_project.add_developer(user)
        maintainer_project.add_maintainer(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute.to_a).to eq([maintainer_project, developer_project, reporter_project])
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

      it 'returns a page of projects ordered by id in descending order' do
        allow(Kaminari.config).to receive(:default_per_page).and_return(2)

        projects = create_list(:project, 2) do |project|
          project.add_developer(user)
        end

        finder = described_class.new(user, project_id: project.id)
        page = finder.execute.to_a

        expect(page.length).to eq(Kaminari.config.default_per_page)
        expect(page[0]).to eq(projects.last)
      end

      it 'returns projects after the given offset id' do
        reporter_project.add_reporter(user)
        developer_project.add_developer(user)
        maintainer_project.add_maintainer(user)

        expect(described_class.new(user, project_id: project.id, offset_id: maintainer_project.id).execute.to_a)
          .to eq([developer_project, reporter_project])

        expect(described_class.new(user, project_id: project.id, offset_id: developer_project.id).execute.to_a)
          .to eq([reporter_project])

        expect(described_class.new(user, project_id: project.id, offset_id: reporter_project.id).execute.to_a)
          .to be_empty
      end
    end

    context 'search' do
      it 'returns projects matching a search query' do
        foo_project = create(:project)
        foo_project.add_maintainer(user)

        wadus_project = create(:project, name: 'wadus')
        wadus_project.add_maintainer(user)

        expect(described_class.new(user, project_id: project.id).execute.to_a)
          .to eq([wadus_project, foo_project])

        expect(described_class.new(user, project_id: project.id, search: 'wadus').execute.to_a)
          .to eq([wadus_project])
      end
    end
  end
end
