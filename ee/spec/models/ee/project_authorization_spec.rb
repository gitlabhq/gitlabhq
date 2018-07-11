require 'spec_helper'

describe ProjectAuthorization do
  describe '.roles_stats' do
    before do
      project1 = create(:project_empty_repo)
      project1.add_reporter(create(:user))

      project2 = create(:project_empty_repo)
      project2.add_developer(create(:user))

      # Add same user as Reporter and Developer to different projects
      # and expect it to be counted once for the stats
      user = create(:user)
      project1.add_reporter(user)
      project2.add_developer(user)
    end

    subject { described_class.roles_stats.to_a }

    it do
      expect(amount_for_kind('reporter')).to eq(1)
      expect(amount_for_kind('developer')).to eq(2)
      expect(amount_for_kind('maintainer')).to eq(2)
    end

    def amount_for_kind(access_level)
      subject.find do |row|
        row['kind'] == access_level
      end['amount'].to_i
    end
  end
end
