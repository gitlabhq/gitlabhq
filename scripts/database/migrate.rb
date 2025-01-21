#!/usr/bin/env ruby
# frozen_string_literal: true

# This script is designed to manage database migrations for GitLab.
# It allows users to selectively run or revert migrations that have been changed in the current Git branch.
# This is especially useful for database reviewers and maintainers
# The script uses the 'fzf' command-line fuzzy finder for interactive selection of migration files.
#
# Examples:
#
# 1. Running migrations:
#    $ ./scripts/database/migrate.rb
#    This will show a list of changed migration files and allow you to select which ones to apply.
#
# 2. Reverting migrations:
#    $ ./scripts/database/migrate.rb -t down
#    This will show a list of changed migration files and allow you to select which ones to revert.
#
# 3. Debug mode:
#    $ ruby scripts/database/migrate.rb --debug
#    This will run the script with additional debug output for troubleshooting.
#
# The script checks for changed migration files in both 'db/migrate' and 'db/post_migrate' directories,
# and executes the selected migrations for both the main and CI databases.

require 'optparse'

SCRIPT_NAME = File.basename($PROGRAM_NAME)
MIGRATIONS_DIR = 'db/migrate'
POST_DEPLOY_MIGRATIONS_DIR = 'db/post_migrate'
BRANCH_NAME = 'master'

def require_commands!(*commands)
  missing_commands = commands.reject { |command| system("command", "-v", command, out: File::NULL) }

  abort("This script requires #{missing_commands.join(', ')} to be installed.") unless missing_commands.empty?
end

def parse_options
  options = {
    task: :up
  }
  OptionParser.new do |opts|
    opts.banner = "Usage: #{SCRIPT_NAME} [options]"

    opts.on('--debug', 'Enable debug mode') do |v|
      options[:debug] = v
    end
    opts.on('-t', '--task=[up|down]', 'Set task - "up" to migrate forward, "down" to rollback') do |v|
      options[:task] = v
    end
  end.parse!

  options
end

def prompt(list, prompt:, multi: false, reverse: false)
  arr = list.join("\n")

  fzf_args = [].tap do |args|
    args << '--layout="reverse"'
    args << '--height=30%'
    args << '--multi' if multi
    args << '--tac' if reverse
  end

  output = IO.popen("echo \"#{arr}\" | fzf #{fzf_args.join(' ')} --prompt=\"#{prompt}\"", &:readlines)
  return [] unless output

  selection = output.join.strip

  return selection unless multi

  selection.split("\n")
end

def get_changed_files(branch_name:)
  set = `git diff --name-only --diff-filter=d $(git merge-base #{branch_name} HEAD)..HEAD #{MIGRATIONS_DIR}`
    .split("\n").to_set
  set += `git diff --diff-filter=d --merge-base --name-only #{branch_name} #{MIGRATIONS_DIR}`.split("\n")

  set
end

# rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity -- we can skip it for this script
def execute
  options = parse_options
  puts "Options: #{options.inspect}" if options[:debug]

  files = get_changed_files(branch_name: BRANCH_NAME)
  puts "Files: #{files.inspect}" if options[:debug]

  base_files = files.map { |path| File.basename(path) }
  puts "Base files: #{base_files.inspect}" if options[:debug]

  if base_files.empty?
    puts 'No migration files found'
    exit 1
  end

  selected_files = prompt(base_files, prompt: 'Select migrations (press tab to select multiple)> ', multi: true)
  puts "Selected files: #{selected_files.inspect}" if options[:debug]

  if selected_files.empty?
    puts 'No files selected'
    exit 1
  end

  sorted = selected_files.sort_by { |f| f.match(/^\d+/)[0].to_i }
  puts "Sorted: #{sorted.inspect}" if options[:debug]

  case options[:task].to_sym
  when :up
    sorted.each do |file|
      version = file.match(/^\d+/)[0].to_i

      cmd = "bin/rails db:migrate:up:main db:migrate:up:ci VERSION=#{version}"
      puts "$ #{cmd}"
      raise "Migration #{version} failed" unless system(cmd)
    end
  when :down
    sorted.reverse_each do |file|
      version = file.match(/^\d+/)[0].to_i
      cmd = "bin/rails db:migrate:down:main db:migrate:down:ci VERSION=#{version}"
      puts "$ #{cmd}"
      raise "Migration #{version} failed" unless system(cmd)
    end
  else
    puts 'Invalid task. Use --task=[up|down]'
    exit 1
  end
end
# rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

require_commands!('fzf')

execute
