#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

# Removes `@gl_introduced` directives tagged with a milestone older than the
# previous one. The backend only acts on directives at the current milestone or
# later (see Gitlab::Graphql::VersionFilter::FutureFieldFilter#future_node?).
# The previous milestone is kept as a buffer, because an MR merged around the
# time the stable branch is cut can miss its release.
class CleanupGlIntroduced
  ROOT = File.expand_path('../..', __dir__)
  SEARCH_PATHS = %w[app/assets ee/app/assets].freeze
  # Same leading `X.Y.Z` match as Gitlab::VersionInfo.parse.
  VERSION_PATTERN = /\A(\d+)\.(\d+)\.(\d+)/
  # GitLab releases X.11 before (X+1).0.
  LAST_MINOR = 11

  DIRECTIVE = /@gl_introduced\(\s*version:\s*"(?<version>[^"]*)"\s*\)/
  # Order matters: a directive alone on its line drops the whole line, one at
  # the start of a line keeps the indentation, any other drops its leading space.
  PATTERNS = [
    /^[ \t]*#{DIRECTIVE}[ \t]*\r?\n/,
    /^(?<indent>[ \t]*)#{DIRECTIVE}[ \t]*/,
    /[ \t]*#{DIRECTIVE}/
  ].freeze

  def self.milestone(version)
    match = VERSION_PATTERN.match(version.to_s.strip)

    [match[1].to_i, match[2].to_i] if match
  end

  def self.previous_milestone((major, minor))
    minor > 0 ? [major, minor - 1] : [major - 1, LAST_MINOR]
  end

  attr_reader :root, :current_milestone

  def initialize(root: ROOT, version: nil, dry_run: false, output: $stdout)
    @root = root
    @dry_run = dry_run
    @output = output

    version ||= File.read(File.join(root, 'VERSION'))
    @current_milestone = self.class.milestone(version)

    raise ArgumentError, "Invalid version: #{version.inspect}" unless current_milestone
  end

  # Returns { relative_path => removed_count } for every file with stale directives.
  def execute
    changes = files.each_with_object({}) do |path, result|
      content = File.read(path, encoding: Encoding::UTF_8)
      cleaned, removed = clean(content)

      next if removed == 0

      File.write(path, cleaned) unless dry_run
      result[relative(path)] = removed
    end

    report(changes)

    changes
  end

  def clean(content)
    removed = 0

    cleaned = PATTERNS.reduce(content) do |text, pattern|
      text.gsub(pattern) do |match|
        directive = Regexp.last_match

        next match unless stale?(directive[:version])

        removed += 1
        directive.names.include?('indent') ? directive[:indent] : ''
      end
    end

    [cleaned, removed]
  end

  def stale?(version)
    milestone = self.class.milestone(version)

    # Unparsable versions are never stripped by the backend, so leave them for a human.
    return false unless milestone

    (milestone <=> cutoff_milestone) < 0
  end

  def milestone_name
    current_milestone.join('.')
  end

  def cutoff_milestone_name
    cutoff_milestone.join('.')
  end

  private

  attr_reader :dry_run, :output

  def cutoff_milestone
    @cutoff_milestone ||= self.class.previous_milestone(current_milestone)
  end

  def files
    SEARCH_PATHS.flat_map { |dir| Dir.glob(File.join(root, dir, '**', '*.graphql')) }.sort
  end

  def relative(path)
    path.delete_prefix("#{root}/")
  end

  def report(changes)
    if changes.empty?
      output.puts "No stale @gl_introduced directives found (older than milestone #{cutoff_milestone_name})."
      return
    end

    verb = dry_run ? 'Would remove' : 'Removed'

    changes.each do |path, count|
      output.puts "#{verb} #{count} stale @gl_introduced directive(s) from #{path}"
    end

    output.puts "#{verb} #{changes.values.sum} directive(s) in #{changes.size} file(s) " \
      "(older than milestone #{cutoff_milestone_name})."
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

    opts.on('--dry-run', 'Print the files that would change without writing them') do
      options[:dry_run] = true
    end

    opts.on('--version', 'Print the milestone that directives are compared against and exit') do
      options[:print_version] = true
    end

    opts.on('-h', '--help', 'Print this help') do
      puts opts
      exit
    end
  end.parse!

  cleanup = CleanupGlIntroduced.new(dry_run: options.fetch(:dry_run, false))

  if options[:print_version]
    puts cleanup.milestone_name
    exit
  end

  cleanup.execute
end
