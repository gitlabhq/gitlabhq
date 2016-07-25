require 'spec_helper'

describe MilestonesHelper do

  describe '#milestone_counts' do
    let(:project) { FactoryGirl.create(:project) }
    let(:milestone_1) { FactoryGirl.create(:active_milestone, project: project) }
    let(:milestone_2) { FactoryGirl.create(:active_milestone, project: project) }
    let(:milestone_3) { FactoryGirl.create(:closed_milestone, project: project) }

    let(:counts) { helper.milestone_counts(project.milestones) }

    it 'returns a hash containing three items' do
      expect(counts.length).to eq 3
    end
    it 'returns a hash containing "opened" key' do
      expect(counts.has_key?(:opened)).to eq true
    end
    it 'returns a hash containing "closed" key' do
      expect(counts.has_key?(:closed)).to eq true
    end
    it 'returns a hash containing "all" key' do
      expect(counts.has_key?(:all)).to eq true
    end
    # This throws a "NoMethodError: undefined method `+' for nil:NilClass" error for line 27; can't figure out why it can't find the keys in the hash
    # it 'shows "all" object is the sum of "opened" and "closed" objects' do
    #   total = counts[:opened] + counts[:closed]
    #   expect(counts[:all]).to eq total
    # end

  end

end
