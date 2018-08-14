require 'spec_helper'

describe MilestonesHelper do
  describe '#milestones_filter_dropdown_path' do
    let(:project) { create(:project) }
    let(:project2) { create(:project) }
    let(:group) { create(:group) }

    context 'when @project present' do
      it 'returns project milestones JSON URL' do
        assign(:project, project)

        expect(helper.milestones_filter_dropdown_path).to eq(project_milestones_path(project, :json))
      end
    end

    context 'when @target_project present' do
      it 'returns targeted project milestones JSON URL' do
        assign(:target_project, project2)

        expect(helper.milestones_filter_dropdown_path).to eq(project_milestones_path(project2, :json))
      end
    end

    context 'when @group present' do
      it 'returns group milestones JSON URL' do
        assign(:group, group)

        expect(helper.milestones_filter_dropdown_path).to eq(group_milestones_path(group, :json))
      end
    end

    context 'when neither of @project/@target_project/@group present' do
      it 'returns dashboard milestones JSON URL' do
        expect(helper.milestones_filter_dropdown_path).to eq(dashboard_milestones_path(:json))
      end
    end
  end

  describe "#milestone_date_range" do
    def result_for(*args)
      milestone_date_range(build(:milestone, *args))
    end

    let(:yesterday) { Date.yesterday }
    let(:tomorrow) { yesterday + 2 }
    let(:format) { '%b %-d, %Y' }
    let(:yesterday_formatted) { yesterday.strftime(format) }
    let(:tomorrow_formatted) { tomorrow.strftime(format) }

    it { expect(result_for(due_date: nil, start_date: nil)).to be_nil }
    it { expect(result_for(due_date: tomorrow)).to eq("expires on #{tomorrow_formatted}") }
    it { expect(result_for(due_date: yesterday)).to eq("expired on #{yesterday_formatted}") }
    it { expect(result_for(start_date: tomorrow)).to eq("starts on #{tomorrow_formatted}") }
    it { expect(result_for(start_date: yesterday)).to eq("started on #{yesterday_formatted}") }
    it { expect(result_for(start_date: yesterday, due_date: tomorrow)).to eq("#{yesterday_formatted}–#{tomorrow_formatted}") }
  end

  describe '#milestone_counts' do
    let(:project) { create(:project) }
    let(:counts) { helper.milestone_counts(project.milestones) }

    context 'when there are milestones' do
      it 'returns the correct counts' do
        create_list(:active_milestone, 2, project: project)
        create(:closed_milestone, project: project)

        expect(counts).to eq(opened: 2, closed: 1, all: 3)
      end
    end

    context 'when there are only milestones of one type' do
      it 'returns the correct counts' do
        create_list(:active_milestone, 2, project: project)

        expect(counts).to eq(opened: 2, closed: 0, all: 2)
      end
    end

    context 'when there are no milestones' do
      it 'returns the correct counts' do
        expect(counts).to eq(opened: 0, closed: 0, all: 0)
      end
    end
  end
end
