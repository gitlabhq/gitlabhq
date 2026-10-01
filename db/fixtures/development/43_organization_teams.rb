# frozen_string_literal: true

Gitlab::Seeder.quiet do
  organization = Organizations::Organization.first

  teams = [
    { name: 'Platform', path: 'platform', description: 'Owns the core platform' },
    { name: 'Design', path: 'design', description: 'Product design and research' },
    { name: 'Support', path: 'support', description: nil }
  ]

  teams.each do |attributes|
    Organizations::Team.create!(attributes.merge(organization: organization))

    print '.'
  rescue StandardError => e
    warn "\nError seeding organization team #{attributes[:path]}: #{e.message}"
  end

  puts "\nSeeded #{teams.size} organization teams"
end
