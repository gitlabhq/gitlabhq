require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20181014131030_enqueue_redact_links_in_epics.rb')

describe EnqueueRedactLinksInEpics, :migration, :sidekiq do
  let(:epics) { table(:epics) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    text = 'some text /sent_notifications/00000000000000000000000000000000/unsubscribe more text'
    user = users.create!(email: 'test@example.com', projects_limit: 100, username: 'test')
    group = namespaces.create!(name: 'gitlab', path: 'gitlab')

    epics.create!(id: 1, iid: 1, title: 'title1', title_html: '', group_id: group.id, author_id: user.id, description: text)
    epics.create!(id: 2, iid: 2, title: 'title2', title_html: '', group_id: group.id, author_id: user.id, description: text)
    epics.create!(id: 3, iid: 3, title: 'title3', title_html: '', group_id: group.id, author_id: user.id, description: 'some other text')
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, "Epic", "description", 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, "Epic", "description", 2, 2)
        expect(BackgroundMigrationWorker.jobs.size).to eq 2
      end
    end
  end
end
