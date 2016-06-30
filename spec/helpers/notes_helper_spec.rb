require "spec_helper"

describe NotesHelper do
  describe "#notes_max_access_for_users" do
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

    it 'return human access levels' do
      original_method = project.team.method(:human_max_access)
      expect_any_instance_of(ProjectTeam).to receive(:human_max_access).exactly(3).times do |*args|
        original_method.call(args[1])
      end

      expect(helper.note_max_access_for_user(owner_note)).to eq('Owner')
      expect(helper.note_max_access_for_user(master_note)).to eq('Master')
      expect(helper.note_max_access_for_user(reporter_note)).to eq('Reporter')
      # Call it again to ensure value is cached
      expect(helper.note_max_access_for_user(owner_note)).to eq('Owner')
    end

    it 'handles access in different projects' do
      second_project = create(:empty_project)
      second_project.team << [master, :reporter]
      other_note = create(:note, author: master, project: second_project)

      expect(helper.note_max_access_for_user(master_note)).to eq('Master')
      expect(helper.note_max_access_for_user(other_note)).to eq('Reporter')
    end
  end
end
