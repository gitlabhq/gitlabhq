require 'spec_helper'

describe Groups::AutocompleteService do
  let!(:group) { create(:group, :nested, avatar: fixture_file_upload('spec/fixtures/dk.png')) }
  let!(:sub_group) { create(:group, parent: group) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group, author: user) }

  before do
    create(:group_member, group: group, user: user)
  end

  def user_to_autocompletable(user)
    {
      username: user.username,
      name: user.name,
      avatar_url: user.avatar_url
    }
  end

  describe '#labels' do
    let!(:label1) { create(:group_label, group: group) }
    let!(:label2) { create(:group_label, group: group) }
    let!(:sub_group_label) { create(:group_label, group: sub_group) }
    let!(:parent_group_label) { create(:group_label, group: group.parent) }

    it 'returns labels from own group and ancestor groups' do
      service = described_class.new(group, user)
      result = service.labels

      expected_labels = [label1, label2, parent_group_label]

      expect(result.size).to eq(3)
      expect(result.map(&:title)).to contain_exactly(*expected_labels.map(&:title))
    end

    context 'some labels are already assigned' do
      before do
        epic.labels << label1
      end

      it 'marks already assigned as set' do
        service = described_class.new(group, user)
        result = service.labels(epic)

        expected_labels = [label1, label2, parent_group_label]

        expect(result.size).to eq(3)
        expect(result.map { |label| label['title'] }).to contain_exactly(*expected_labels.map(&:title))

        epic.labels.each do |assigned_label|
          expect(result.find { |label| label['title'] == assigned_label.title }[:set]).to eq(true)
        end
      end
    end
  end
end
