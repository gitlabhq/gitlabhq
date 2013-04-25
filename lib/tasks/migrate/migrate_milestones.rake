desc "GITLAB | Migrate Milestones"
task migrate_milestones: :environment do
  Milestone.where(state: nil).update_all(state: 'active')
end
