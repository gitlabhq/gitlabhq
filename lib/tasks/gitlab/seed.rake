# frozen_string_literal: true

namespace :gitlab do
  namespace :seed do
    def projects_from_args(args)
      full_path = args.project_full_path

      if full_path
        project = Project.find_by_full_path(full_path)

        unless project
          error_message = "Project '#{full_path}' does not exist!"
          potential_projects = Project.search(full_path)

          if potential_projects.present?
            error_message += " Did you mean '#{potential_projects.first.full_path}'?"
          end

          puts Rainbow(error_message).red
          exit 1
        end

        [project]
      else
        scope = Project.respond_to?(:not_mass_generated) ? Project.not_mass_generated : Project
        scope.find_each
      end
    end

    desc "GitLab | Seed | Seeds issues"
    task :issues, [:project_full_path, :backfill_weeks, :average_issues_per_week] => :environment do |t, args|
      args.with_defaults(backfill_weeks: 5, average_issues_per_week: 2)

      projects = projects_from_args(args)

      projects.each do |project|
        puts "\nSeeding issues for the '#{project.full_path}' project"
        seeder = Quality::Seeders::Issues.new(project: project)
        issues_created = seeder.seed(backfill_weeks: args.backfill_weeks.to_i,
          average_issues_per_week: args.average_issues_per_week.to_i)
        puts "\n#{issues_created} issues created!"
      end
    end

    task :epics, [:group_full_path, :backfill_weeks, :average_issues_per_week] => :environment do |t, args|
      args.with_defaults(backfill_weeks: 5, average_issues_per_week: 2)

      groups =
        if args.group_full_path
          group = Group.find_by_full_path(args.group_full_path)

          unless group
            error_message = "Group '#{args.group_full_path}' does not exist!"
            potential_groups = Group.search(args.group_full_path)

            if potential_groups.present?
              error_message += " Did you mean '#{potential_groups.first.full_path}'?"
            end

            puts Rainbow(error_message).red
            exit 1
          end

          [group]
        else
          Group.not_mass_generated.find_each
        end

      groups.each do |group|
        puts "\nSeeding epics for the '#{group.full_path}' group"
        seeder = Quality::Seeders::Epics.new(group: group)
        epics = seeder.seed(
          backfill_weeks: args.backfill_weeks.to_i,
          average_issues_per_week: args.average_issues_per_week.to_i
        )
        puts "\n#{epics} epics created!"
      end
    end

    desc "GitLab | Seed | Seed a project with vulnerabilities"
    task :vulnerabilities, [:project_full_path] => :environment do |t, args|
      projects = projects_from_args(args)

      projects.each do |project|
        puts "\nSeeding vulnerabilities for the '#{project.full_path}' project"
        seeder = Quality::Seeders::Vulnerabilities.new(project)
        seeder.seed!
        puts "\nDone."
      end
    end

    desc "GitLab | Seed | Seed a new group with dependencies"
    task :dependencies, [] => :environment do |t, args|
      puts "\nSeeding a new group with dependencies"
      seeder = Quality::Seeders::Dependencies.new
      seeder.seed!
      puts "\nDone."
    end
  end
end
