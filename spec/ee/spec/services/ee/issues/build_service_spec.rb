require 'spec_helper.rb'

describe Issues::BuildService do # rubocop:disable RSpec/FilePath
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :developer]
  end

  context 'with an issue template' do
    describe '#execute' do
      it 'fills in the template in the description' do
        project = build(:project, issues_template: 'Work hard, play hard!')
        service = described_class.new(project, user)

        issue = service.execute

        expect(issue.description).to eq('Work hard, play hard!')
      end
    end
  end

  context 'for a single discussion' do
    describe '#execute' do
      let(:merge_request) { create(:merge_request, title: "Hello world", source_project: project) }
      let(:discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, note: "Almost done").to_discussion }
      let(:service) { described_class.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid, discussion_to_resolve: discussion.id) }

      context 'with an issue template' do
        let(:project) { create(:project, :repository, issues_template: 'Work hard, play hard!') }

        it 'picks the discussion description over the issue template' do
          issue = service.execute

          expect(issue.description).to include('Almost done')
        end
      end
    end
  end
end
