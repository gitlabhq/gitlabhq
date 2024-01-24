#!/usr/bin/env ruby
#
# Generate a SaaS feature entry file in the correct location.
#
# Automatically stages the file and amends the previous commit if the `--amend`
# argument is used.

require 'fileutils'
require 'httparty'
require 'json'
require 'optparse'
require 'readline'
require 'shellwords'
require 'uri'
require 'yaml'

require_relative '../lib/gitlab/popen'

module SaasFeatureHelpers
  Abort = Class.new(StandardError)
  Done = Class.new(StandardError)

  def capture_stdout(cmd)
    output = IO.popen(cmd, &:read)
    fail_with "command failed: #{cmd.join(' ')}" unless $?.success?
    output
  end

  def fail_with(message)
    raise Abort, "\e[31merror\e[0m #{message}"
  end
end

class SaasFeatureOptionParser
  extend SaasFeatureHelpers

  WWW_GITLAB_COM_SITE = 'https://about.gitlab.com'
  WWW_GITLAB_COM_GROUPS_JSON = "#{WWW_GITLAB_COM_SITE}/groups.json".freeze
  COPY_COMMANDS = [
    'pbcopy', # macOS
    'xclip -selection clipboard', # Linux
    'xsel --clipboard --input', # Linux
    'wl-copy' # Wayland
  ].freeze
  OPEN_COMMANDS = [
    'open', # macOS
    'xdg-open' # Linux
  ].freeze

  Options = Struct.new(
    :name,
    :group,
    :milestone,
    :amend,
    :dry_run,
    :force,
    :introduced_by_url,
    keyword_init: true
  )

  class << self
    def parse(argv)
      options = Options.new

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options] <saas-feature>\n\n"

        # Note: We do not provide a shorthand for this in order to match the `git
        # commit` interface
        opts.on('--amend', 'Amend the previous commit') do |value|
          options.amend = value
        end

        opts.on('-f', '--force', 'Overwrite an existing entry') do |value|
          options.force = value
        end

        opts.on('-m', '--introduced-by-url [string]', String, 'URL of merge request introducing the SaaS feature') do |value|
          options.introduced_by_url = value
        end

        opts.on('-M', '--milestone [string]', String, 'Milestone in which the SaaS feature was introduced') do |value|
          options.milestone = value
        end

        opts.on('-n', '--dry-run', "Don't actually write anything, just print") do |value|
          options.dry_run = value
        end

        opts.on('-g', '--group [string]', String, 'The group introducing a SaaS feature, like: `group::project management`') do |value|
          options.group = value if group_labels.include?(value)
        end

        opts.on('-h', '--help', 'Print help message') do
          $stdout.puts opts
          raise Done.new
        end
      end

      parser.parse!(argv)

      unless argv.one?
        $stdout.puts parser.help
        $stdout.puts
        raise Abort, 'SaaS feature name is required'
      end

      # Name is a first name
      options.name = argv.first.downcase.tr('-', '_')

      options
    end

    def groups
      @groups ||= fetch_json(WWW_GITLAB_COM_GROUPS_JSON)
    end

    def group_labels
      @group_labels ||= groups.map { |_, group| group['label'] }.sort
    end

    def find_group_by_label(label)
      groups.find { |_, group| group['label'] == label }[1]
    end

    def group_list
      group_labels.map.with_index do |group_label, index|
        "#{index + 1}. #{group_label}"
      end
    end

    def fzf_available?
      find_compatible_command(%w[fzf])
    end

    def prompt_readline(prompt:)
      Readline.readline('?> ', false)&.strip
    end

    def prompt_fzf(list:, prompt:)
      arr = list.join("\n")

      selection = IO.popen(%W[fzf --tac --prompt #{prompt}], "r+") do |pipe|
        pipe.puts(arr)
        pipe.close_write
        pipe.readlines
      end.join.strip

      selection[/(\d+)\./, 1]
    end

    def print_list(list)
      return if list.empty?

      $stdout.puts list.join("\n")
    end

    def print_prompt(prompt)
      $stdout.puts
      $stdout.puts ">> #{prompt}:"
      $stdout.puts
    end

    def prompt_list(prompt:, list: nil)
      if fzf_available?
        prompt_fzf(list: list, prompt: prompt)
      else
        prompt_readline(prompt: prompt)
      end
    end

    def fetch_json(json_url)
      json = with_retries { HTTParty.get(json_url, format: :plain) }
      JSON.parse(json)
    end

    def with_retries(attempts: 3)
      yield
    rescue Errno::ECONNRESET, OpenSSL::SSL::SSLError, Net::OpenTimeout
      retry if (attempts -= 1).positive?
      raise
    end

    def read_group
      prompt = 'Specify the group label to which the SaaS feature belongs, from the following list'

      unless fzf_available?
        print_prompt(prompt)
        print_list(group_list)
      end

      loop do
        group = prompt_list(prompt: prompt, list: group_list)
        group = group_labels[group.to_i - 1] unless group.to_i.zero?

        if group_labels.include?(group)
          $stdout.puts "You picked the group '#{group}'"
          return group
        else
          $stderr.puts "The group label isn't in the above labels list"
        end

      end
    end

    def read_introduced_by_url
      read_url('URL of the MR introducing the SaaS feature (enter to skip and let Danger provide a suggestion directly in the MR):')
    end

    def read_milestone
      milestone = File.read('VERSION')
      milestone.gsub(/^(\d+\.\d+).*$/, '\1').chomp
    end

    def read_url(prompt)
      $stdout.puts
      $stdout.puts ">> #{prompt}"

      loop do
        url = Readline.readline('?> ', false)&.strip
        url = nil if url.empty?
        return url if url.nil? || valid_url?(url)
      end
    end

    def valid_url?(url)
      unless url.start_with?('https://')
        $stderr.puts 'URL needs to start with https://'
        return false
      end

      response = HTTParty.head(url)

      return true if response.success?

      $stderr.puts "URL '#{url}' isn't valid!"
    end

    def open_url!(url)
      _, open_url_status = Gitlab::Popen.popen([open_command, url])

      open_url_status
    end

    def copy_to_clipboard!(text)
      IO.popen(copy_to_clipboard_command.shellsplit, 'w') do |pipe|
        pipe.print(text)
      end
    end

    def copy_to_clipboard_command
      find_compatible_command(COPY_COMMANDS)
    end

    def open_command
      find_compatible_command(OPEN_COMMANDS)
    end

    def find_compatible_command(commands)
      commands.find do |command|
        Gitlab::Popen.popen(%W[which #{command.split(' ')[0]}])[1] == 0
      end
    end
  end
end

class SaasFeatureCreator
  include SaasFeatureHelpers

  attr_reader :options

  def initialize(options)
    @options = options
  end

  def execute
    assert_feature_branch!
    assert_name!
    assert_existing_saas_feature!

    options.group ||= SaasFeatureOptionParser.read_group
    options.introduced_by_url ||= SaasFeatureOptionParser.read_introduced_by_url
    options.milestone ||= SaasFeatureOptionParser.read_milestone

    $stdout.puts "\e[32mcreate\e[0m #{file_path}"
    $stdout.puts contents

    unless options.dry_run
      write
      amend_commit if options.amend
    end

    if editor
      system(editor, file_path)
    end
  end

  private

  def contents
    config_hash.to_yaml
  end

  def config_hash
    {
      'name'              => options.name,
      'introduced_by_url' => options.introduced_by_url,
      'milestone'         => options.milestone,
      'group'             => options.group
    }
  end

  def write
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, contents)
  end

  def editor
    ENV['EDITOR']
  end

  def amend_commit
    fail_with 'git add failed' unless system(*%W[git add #{file_path}])

    system('git commit --amend')
  end

  def assert_feature_branch!
    return unless branch_name == 'master'

    fail_with 'Create a branch first!'
  end

  def assert_existing_saas_feature!
    existing_path = all_saas_feature_names[options.name]
    return unless existing_path
    return if options.force

    fail_with "#{existing_path} already exists! Use `--force` to overwrite."
  end

  def assert_name!
    return if options.name.match(/\A[a-z0-9_-]+\Z/)

    fail_with 'Provide a name for the SaaS feature that is [a-z0-9_-]'
  end

  def file_path
    saas_features_path.sub('*.yml', options.name + '.yml')
  end

  def all_saas_feature_names
    # check flatten needs
    @all_saas_feature_names ||=
      Dir.glob(saas_features_path).map do |path|
        [File.basename(path, '.yml'), path]
      end.to_h
  end

  def saas_features_path
    File.join('ee', 'config', 'saas_features', '*.yml')
  end

  def branch_name
    @branch_name ||= capture_stdout(%w[git symbolic-ref --short HEAD]).strip
  end
end

if $0 == __FILE__
  begin
    options = SaasFeatureOptionParser.parse(ARGV)
    SaasFeatureCreator.new(options).execute
  rescue SaasFeatureHelpers::Abort => ex
    $stderr.puts ex.message
    exit 1
  rescue SaasFeatureHelpers::Done
    exit
  end
end

# vim: ft=ruby
