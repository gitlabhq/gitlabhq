require 'spec_helper'

describe BlameHelper do
  describe '#get_age_map_start_date' do
    let(:dates) do
      [Time.zone.local(2014, 3, 17, 0, 0, 0),
       Time.zone.local(2011, 11, 2, 0, 0, 0),
       Time.zone.local(2015, 7, 9, 0, 0, 0),
       Time.zone.local(2013, 2, 24, 0, 0, 0),
       Time.zone.local(2010, 9, 22, 0, 0, 0)]
    end
    let(:blame_groups) do
      [
        { commit: double(committed_date: dates[0]) },
        { commit: double(committed_date: dates[1]) },
        { commit: double(committed_date: dates[2]) }
      ]
    end

    it 'returns the earliest date from a blame group' do
      project = double(created_at: dates[3])

      duration = helper.age_map_duration(blame_groups, project)

      expect(duration[:started_days_ago]).to eq((duration[:now] - dates[1]).to_i / 1.day)
    end

    it 'returns the earliest date from a project' do
      project = double(created_at: dates[4])

      duration = helper.age_map_duration(blame_groups, project)

      expect(duration[:started_days_ago]).to eq((duration[:now] - dates[4]).to_i / 1.day)
    end
  end

  describe '#age_map_class' do
    let(:dates) do
      [Time.zone.local(2014, 3, 17, 0, 0, 0)]
    end
    let(:blame_groups) do
      [
        { commit: double(committed_date: dates[0]) }
      ]
    end
    let(:duration) do
      project = double(created_at: dates[0])
      helper.age_map_duration(blame_groups, project)
    end

    it 'returns blame-commit-age-9 when oldest' do
      expect(helper.age_map_class(dates[0], duration)).to eq 'blame-commit-age-9'
    end

    it 'returns blame-commit-age-0 class when newest' do
      expect(helper.age_map_class(duration[:now], duration)).to eq 'blame-commit-age-0'
    end
  end
end
