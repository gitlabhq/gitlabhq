# frozen_string_literal: true

return if Rails.env.production?

desc "GitLab | bundler tasks"
namespace :bundler do
  namespace :gemfile do
    desc "GitLab | bundler tasks | sync Gemfilex"
    task :sync do
      require 'rainbow/refinement'
      using Rainbow

      Bundler.with_original_env do
        [
          ['bundle install', 'installing Gemfile failed'],
          ['bundle exec bundler-checksum init', 'updating bundler-checksum failed'],
          ['cp Gemfile.lock Gemfile.next.lock', 'copying Gemfile.lock to Gemfile.next.lock failed'],
          ['BUNDLE_GEMFILE=Gemfile.next bundle lock', 'updating Gemfile.next failed'],
          ['BUNDLE_GEMFILE=Gemfile.next bundle install', 'installing Gemfile.next failed'],
          ['BUNDLE_GEMFILE=Gemfile.next bundle exec bundler-checksum init', 'updating bundler-checksum (next) failed']
        ].each do |(command, error)|
          run_bundler(command, error)
        end
      end
    end

    desc "GitLab | bundler tasks | check Gemfiles"
    task :check do
      require 'rainbow/refinement'
      using Rainbow

      Bundler.with_original_env do
        [
          ['bundle lock --print | diff Gemfile.lock -',
            'inconsistent Gemfile.lock detected, run `bundle exec rake bundler:gemfile:sync`'],
          ['bundle exec bundler-checksum lint',
            'inconsistent bundler-checksum detected, run `bundle exec rake bundler:gemfile:sync`'],
          ['BUNDLE_GEMFILE=Gemfile.next bundle lock --print --lockfile Gemfile.lock | diff Gemfile.next.lock -',
            'inconsistent Gemfile.next.lock detected, run `bundle exec rake bundler:gemfile:sync`'],
          ['BUNDLE_GEMFILE=Gemfile.next bundle exec bundler-checksum lint',
            'inconsistent bundler-checksum (next) detected, run `bundle exec rake bundler:gemfile:sync`']
        ].each do |(command, error)|
          run_bundler(command, error)
        end
      end
    end

    def from_lefthook?
      %w[1 true].include?(ENV['FROM_LEFTHOOK'])
    end

    def run_bundler(command, error)
      puts "Running `#{command}`:".underline unless from_lefthook?
      out, err, status = Open3.capture3(command)
      if status.success?
        puts "ok".green, "" unless from_lefthook?
      else
        puts out unless from_lefthook?
        puts err.to_s.red unless from_lefthook?
        abort(error)
      end
    end
  end
end
