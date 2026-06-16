#!/usr/bin/env ruby
#
# Generate a Dedicated feature entry file in the correct location.
#
# Automatically stages the file and amends the previous commit if the `--amend`
# argument is used.

require 'optparse'
require 'yaml'

require_relative 'lib/feature_generator/shared'

class DedicatedFeatureOptionParser
  extend FeatureGenerator::Shared::Helpers
  extend FeatureGenerator::Shared::OptionParserMixin

  NOUN = 'Dedicated feature'

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
        opts.banner = "Usage: #{__FILE__} [options] <dedicated-feature>\n\n"

        # Note: We do not provide a shorthand for this in order to match the `git
        # commit` interface
        opts.on('--amend', 'Amend the previous commit') do |value|
          options.amend = value
        end

        opts.on('-f', '--force', 'Overwrite an existing entry') do |value|
          options.force = value
        end

        opts.on('-m', '--introduced-by-url [string]', String, 'URL of merge request introducing the Dedicated feature') do |value|
          options.introduced_by_url = value
        end

        opts.on('-M', '--milestone [string]', String, 'Milestone in which the Dedicated feature was introduced') do |value|
          options.milestone = value
        end

        opts.on('-n', '--dry-run', "Don't actually write anything, just print") do |value|
          options.dry_run = value
        end

        opts.on('-g', '--group [string]', String, 'The group introducing a Dedicated feature, like: `group::project management`') do |value|
          options.group = value if group_labels.include?(value)
        end

        opts.on('-h', '--help', 'Print help message') do
          $stdout.puts opts
          raise FeatureGenerator::Shared::Done
        end
      end

      parser.parse!(argv)

      unless argv.one?
        $stdout.puts parser.help
        $stdout.puts
        raise FeatureGenerator::Shared::Abort, 'Dedicated feature name is required'
      end

      # Normalize name: downcase, hyphens to underscores
      options.name = argv.first.downcase.tr('-', '_')

      options
    end

    def read_group
      super(noun: NOUN)
    end

    def read_introduced_by_url
      super(noun: NOUN)
    end
  end
end

class DedicatedFeatureCreator
  include FeatureGenerator::Shared::Helpers
  include FeatureGenerator::Shared::CreatorMixin

  CONFIG_DIR = File.join('ee', 'config', 'dedicated_features')
  NOUN       = 'Dedicated feature'

  attr_reader :options

  def initialize(options)
    @options = options
  end

  def execute
    assert_feature_branch!
    assert_name!(noun: NOUN)
    assert_existing_dedicated_feature!

    options.group ||= DedicatedFeatureOptionParser.read_group
    options.introduced_by_url ||= DedicatedFeatureOptionParser.read_introduced_by_url
    options.milestone ||= DedicatedFeatureOptionParser.read_milestone

    $stdout.puts "\e[32mcreate\e[0m #{file_path}"
    $stdout.puts contents

    unless options.dry_run
      write
      amend_commit if options.amend
    end

    system(editor, file_path) if editor
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

  def file_path
    File.join(CONFIG_DIR, "#{options.name}.yml")
  end

  def assert_existing_dedicated_feature!
    existing_path = all_dedicated_feature_names[options.name]
    return unless existing_path
    return if options.force

    fail_with "#{existing_path} already exists! Use `--force` to overwrite."
  end

  def all_dedicated_feature_names
    @all_dedicated_feature_names ||=
      Dir.glob(File.join(CONFIG_DIR, '*.yml')).to_h do |path|
        [File.basename(path, '.yml'), path]
      end
  end
end

if $0 == __FILE__
  begin
    options = DedicatedFeatureOptionParser.parse(ARGV)
    DedicatedFeatureCreator.new(options).execute
  rescue FeatureGenerator::Shared::Abort => ex
    $stderr.puts ex.message
    exit 1
  rescue FeatureGenerator::Shared::Done
    exit
  end
end

# vim: ft=ruby
