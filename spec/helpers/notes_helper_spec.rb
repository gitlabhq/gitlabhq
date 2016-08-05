require "spec_helper"

describe NotesHelper do
  let(:owner) { create(:owner) }
  let(:group) { create(:group) }
  let(:project) { create(:empty_project, namespace: group) }
  let(:master) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }

  let(:owner_note) { create(:note, author: owner, project: project) }
  let(:master_note) { create(:note, author: master, project: project) }
  let(:reporter_note) { create(:note, author: reporter, project: project) }
  let!(:notes) { [owner_note, master_note, reporter_note] }

  before do
    group.add_owner(owner)
    project.team << [master, :master]
    project.team << [reporter, :reporter]
    project.team << [guest, :guest]
  end

  describe "#notes_max_access_for_users" do
    it 'return human access levels' do
      expect(helper.note_max_access_for_user(owner_note)).to eq('Owner')
      expect(helper.note_max_access_for_user(master_note)).to eq('Master')
      expect(helper.note_max_access_for_user(reporter_note)).to eq('Reporter')
    end

    it 'handles access in different projects' do
      second_project = create(:empty_project)
      second_project.team << [master, :reporter]
      other_note = create(:note, author: master, project: second_project)

      expect(helper.note_max_access_for_user(master_note)).to eq('Master')
      expect(helper.note_max_access_for_user(other_note)).to eq('Reporter')
    end
  end

  describe '#preload_max_access_for_authors' do
    before do
      RequestStore.clear! # make sure cache were cleared
    end

    it 'loads multiple users' do
      expected_access = {
        owner.id => Gitlab::Access::OWNER,
        master.id => Gitlab::Access::MASTER,
        reporter.id => Gitlab::Access::REPORTER
      }

      expect(helper.preload_max_access_for_authors(notes, project)).to eq(expected_access)
    end
  end
end
