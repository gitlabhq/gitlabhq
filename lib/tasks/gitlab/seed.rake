namespace :gitlab do
  namespace :seed do
    desc "GitLab | Seed | Seeds issues"
    task :issues, [:project_full_path, :backfill_weeks, :average_issues_per_week] => :environment do |t, args|
      args.with_defaults(backfill_weeks: 5, average_issues_per_week: 2)

      projects =
        if args.project_full_path
          project = Project.find_by_full_path(args.project_full_path)

          unless project
            error_message = "Project '#{args.project_full_path}' does not exist!"
            potential_projects = Project.search(args.project_full_path)

            if potential_projects.present?
              error_message += " Did you mean '#{potential_projects.first.full_path}'?"
            end

            puts error_message.color(:red)
            exit 1
          end

          [project]
        else
          Project.not_mass_generated.find_each
        end

      projects.each do |project|
        puts "\nSeeding issues for the '#{project.full_path}' project"
        seeder = Quality::Seeders::Issues.new(project: project)
        issues_created = seeder.seed(backfill_weeks: args.backfill_weeks.to_i,
                                     average_issues_per_week: args.average_issues_per_week.to_i)
        puts "\n#{issues_created} issues created!"
      end
    end
  end
end
