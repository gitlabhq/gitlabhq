# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20180618193715_schedule_prune_orphaned_geo_events.rb')

describe SchedulePruneOrphanedGeoEvents, :migration do
  describe '#up' do
    it 'delegates work to Gitlab::BackgroundMigration::PruneOrphanedGeoEvents', :postgresql do
      expect(BackgroundMigrationWorker).to receive(:perform_async).with('PruneOrphanedGeoEvents')

      migrate!
    end
  end
end
