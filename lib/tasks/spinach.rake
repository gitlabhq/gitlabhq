Rake::Task["spinach"].clear if Rake::Task.task_defined?('spinach')

namespace :spinach do
  namespace :project do
    desc "GitLab | Spinach | Run project commits, issues and merge requests spinach features"
    task :half do
      run_spinach_tests('@project_commits,@project_issues,@project_merge_requests')
    end

    desc "GitLab | Spinach | Run remaining project spinach features"
    task :rest do
      run_spinach_tests('~@admin,~@dashboard,~@profile,~@public,~@snippets,~@project_commits,~@project_issues,~@project_merge_requests')
    end
  end

  desc "GitLab | Spinach | Run project spinach features"
  task :project do
    run_spinach_tests('~@admin,~@dashboard,~@profile,~@public,~@snippets')
  end

  desc "GitLab | Spinach | Run other spinach features"
  task :other do
    run_spinach_tests('@admin,@dashboard,@profile,@public,@snippets')
  end

  desc "GitLab | Spinach | Run other spinach features"
  task :builds do
    run_spinach_tests('@builds')
  end
end

desc "GitLab | Run spinach"
task :spinach do
  run_spinach_tests(nil)
end

def run_system_command(cmd)
  system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd)
end

def run_spinach_command(args)
  run_system_command(%w(spinach -r rerun) + args)
end

def run_spinach_tests(tags)
  success = run_spinach_command(%W(--tags #{tags}))
  3.times do |_|
    break if success
    break unless File.exist?('tmp/spinach-rerun.txt')

    tests = File.foreach('tmp/spinach-rerun.txt').map(&:chomp)
    puts ''
    puts "Spinach tests for #{tags}: Retrying tests... #{tests}".color(:red)
    puts ''
    sleep(3)
    success = run_spinach_command(tests)
  end

  raise("spinach tests for #{tags} failed!") unless success
end
