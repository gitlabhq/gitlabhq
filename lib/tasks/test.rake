# frozen_string_literal: true

Rake::Task["test"].clear

desc "GitLab | List rake tasks for tests"
task :test do
  puts "Running the full GitLab test suite takes significant time to pass. We recommend using one of the following spec tasks:\n\n"

  spec_tasks = Rake::Task.tasks.select { |t| t.name.start_with?('spec:') }
  longest_task_name = spec_tasks.map { |t| t.name.size }.max

  spec_tasks.each do |task|
    puts "#{"%-#{longest_task_name}s" % task.name} | #{task.full_comment}"
  end

  puts "\nLearn more at https://docs.gitlab.com/ee/development/rake_tasks.html#run-tests."
end
