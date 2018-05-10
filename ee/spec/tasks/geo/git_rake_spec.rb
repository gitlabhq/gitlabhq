require 'rake_helper'

describe 'geo:git:housekeeping' do
  set(:project) { create(:project, :repository) }
  set(:registry) { ::Geo::ProjectRegistry.find_or_create_by!(project: project) }

  shared_examples 'housekeeping task' do |task_name, period_name|
    it "sets existing projects syncs_gc count to #{period_name}-1" do
      period = Gitlab::CurrentSettings.send(period_name)

      expect { run_rake_task(task_name) }.to change { registry.syncs_since_gc }.to(period - 1)
    end
  end

  before do
    Rake.application.rake_require 'tasks/geo/git'
    silence_progress_bar
  end

  after do
    registry.reset_syncs_since_gc!
  end

  describe 'geo:git:housekeeping:gc' do
    it_behaves_like 'housekeeping task', 'geo:git:housekeeping:gc', :housekeeping_gc_period
  end

  describe 'geo:git:housekeeping:full_repack' do
    it_behaves_like 'housekeeping task', 'geo:git:housekeeping:full_repack', :housekeeping_full_repack_period
  end

  describe 'geo:git:housekeeping:incremental_repack' do
    it_behaves_like 'housekeeping task', 'geo:git:housekeeping:incremental_repack', :housekeeping_incremental_repack_period
  end
end
