require './spec/support/sidekiq'
require './spec/support/test_env'

class Gitlab::Seeder::Burndown
  def initialize(project, perf: false)
    @project = project
  end

  def seed!
    Sidekiq::Testing.inline! do
      create_milestone
      puts '.'

      create_issues
      puts '.'

      close_issues
      puts '.'
    end

    print '.'
  end

  private

  def create_milestone
    milestone_params = {
      title: "Sprint - #{FFaker::Lorem.sentence}",
      description: FFaker::Lorem.sentence,
      state: 'active',
      start_date: Date.today,
      due_date: rand(15..30).days.from_now
    }

    @milestone = Milestones::CreateService.new(@project, @project.team.users.sample, milestone_params).execute
  end

  def create_issues
    40.times do
      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: 'opened',
        milestone: @milestone,
        assignee: @project.team.users.sample
      }

      Issues::CreateService.new(@project, @project.team.users.sample, issue_params).execute
    end
  end

  def close_issues
    @milestone.start_date.upto(@milestone.due_date) do |date|
      Timecop.travel(date)

      close_number = rand(1..3)
      open_issues = @milestone.issues.where(state: "opened")
      open_issues = open_issues.slice(0..close_number)

      open_issues.each do |issue|
        Issues::CloseService.new(@project, @project.team.users.sample, {}).execute(issue)
      end
    end

    Timecop.return
  end
end

Gitlab::Seeder.quiet do
  if project_id = ENV['PROJECT_ID']
    project = Project.find(project_id)
    seeder = Gitlab::Seeder::Burndown.new(project)
    seeder.seed!
  else
    Project.all.each do |project|
      seeder = Gitlab::Seeder::Burndown.new(project)
      seeder.seed!
    end
  end
end
