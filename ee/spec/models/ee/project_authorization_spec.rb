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
      expect(subject).to include({ 'kind' => 'reporter', 'amount' => '1' })
      expect(subject).to include({ 'kind' => 'developer', 'amount' => '2' })
      expect(subject).to include({ 'kind' => 'master', 'amount' => '2' })
    end
  end
end
