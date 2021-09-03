# frozen_string_literal: true

class Gitlab::Seeder::ErrorTrackingSeeder
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def seed
    parsed_event = Gitlab::Json.parse(read_fixture_file('parsed_event.json'))

    ErrorTracking::CollectErrorService
      .new(project, nil, event: parsed_event)
      .execute
  end

  private

  def read_fixture_file(file)
    File.read(fixture_path(file))
  end

  def fixture_path(file)
    Rails.root.join('spec', 'fixtures', 'error_tracking', file)
  end
end


Gitlab::Seeder.quiet do
  admin_user = User.admins.first

  Project.not_mass_generated.visible_to_user(admin_user).sample(1).each do |project|
    puts "\nActivating integrated error tracking for the '#{project.full_path}' project"

    puts '- enabling in settings'
    project.error_tracking_setting || project.create_error_tracking_setting
    project.error_tracking_setting.update!(enabled: true, integrated: true)

    puts '- seeding an error'
    seeder = Gitlab::Seeder::ErrorTrackingSeeder.new(project)
    seeder.seed
  end
end
