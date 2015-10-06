require 'spec_helper'

describe TrendingProjectsFinder do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  let(:project1) { create(:empty_project, :public, group: group) }
  let(:project2) { create(:empty_project, :public, group: group) }

  before do
    2.times do
      create(:note_on_commit, project: project1)
    end

    create(:note_on_commit, project: project2)
  end

  describe '#execute' do
    describe 'without an explicit start date' do
      subject { described_class.new.execute(user).to_a }

      it 'sorts Projects by the amount of notes in descending order' do
        expect(subject).to eq([project1, project2])
      end
    end

    describe 'with an explicit start date' do
      let(:date) { 2.months.ago }

      subject { described_class.new.execute(user, date).to_a }

      before do
        2.times do
          create(:note_on_commit, project: project2, created_at: date)
        end
      end

      it 'sorts Projects by the amount of notes in descending order' do
        expect(subject).to eq([project2, project1])
      end
    end
  end
end
