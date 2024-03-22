# frozen_string_literal: true

class Gitlab::Seeder::Timelogs
  attr_reader :project, :issues, :merge_requests, :users

  def initialize(project, users)
    @project = project
    @issues = project.issues
    @merge_requests = project.merge_requests
    @users = users
  end

  def seed!
    ensure_users_are_reporters

    print "\nGenerating time entries for issues and merge requests in '#{project.full_path}'\n"
    seed_on_issuables(issues)
    seed_on_issuables(merge_requests)
  end

  def self.find_or_create_reporters
    password = SecureRandom.hex.slice(0, 16)

    [
      User.find_by_username("root"),
      find_or_create_reporter_user("timelogs_reporter_user_1", password),
      find_or_create_reporter_user("timelogs_reporter_user_2", password)
    ].compact
  end

  private

  def ensure_users_are_reporters
    team = ProjectTeam.new(project)

    users.each do |user|
      unless team.member?(user, Gitlab::Access::REPORTER)
        print "\nAdding #{user.username} to #{project.full_path} reporters"
        team.add_reporter(user)
      end
    end
  end

  def seed_on_issuables(issuables)
    min_date = Time.now - 2.months
    max_date = Time.now

    issuables.each do |issuable|
      rand(2..5).times do
        timelog_author = users.sample

        ::Timelogs::CreateService.new(
          issuable, rand(10..120) * 60, rand(min_date..max_date), FFaker::Lorem.sentence, timelog_author
        ).execute

        print '.'
      end
    end
  end

  def self.find_or_create_reporter_user(username, password)
    user = User.find_by_username(username)
    if user.nil?
      print "\nCreating user '#{username}' with password: '#{password}'"

      User.create!(
        username: username,
        name: FFaker::Name.name,
        email: FFaker::Internet.email,
        confirmed_at: DateTime.now,
        password: password
      ) do |user|
        user.assign_personal_namespace(Organizations::Organization.default_organization)
      end
    end

    user
  end
end

if ENV['SEED_TIMELOGS']
  Gitlab::Seeder.quiet do
    users = Gitlab::Seeder::Timelogs.find_or_create_reporters

    # Seed timelogs for the first 5 projects
    projects = Project.first(5)

    # Always seed timelogs to the Flight project
    flight_project = Project.find_by_full_path("flightjs/Flight")
    projects |= [flight_project] unless flight_project.nil?

    projects.each do |project|
      Gitlab::Seeder::Timelogs.new(project, users).seed! unless project.nil?
    end

  rescue => e
    warn "\nError seeding timelogs: #{e}"
  end
else
  puts "Skipped. Use the `SEED_TIMELOGS` environment variable to enable seeding timelogs data."
end
