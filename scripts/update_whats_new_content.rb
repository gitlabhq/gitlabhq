#!/usr/bin/env ruby
# frozen_string_literal: true

# Creates latest what's new release YAML.
#
# Requirements:
#   - Generate the latest what's new file under data/whats_new/ (on release day)
#   - Require a template file under data/whats_new/templates/ (YYYYMMDD0001_XX_YY.yml)
#   - Include all features for current release sorted by weight (ascending).
#     Features without weight will be sorted to the bottom of the list.
#
# Setting WHATS_NEW_FORCE drops the release-day requirement and targets whichever
# release is nearest to today, so the file can be generated on demand.
#
# Local testing:
#   - WHATS_NEW_TODAY=2026-07-16 ruby scripts/update_whats_new_content.rb
#   - WHATS_NEW_FORCE=true ruby scripts/update_whats_new_content.rb
#

require 'net/http'
require 'yaml'
require 'date'

class UpdateWhatsNewContent
  ROOT = File.expand_path('..', __dir__)
  RELEASES_YML_URL = 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/releases.yml'
  DOCS_BASE_URL = 'https://docs.gitlab.com/'
  RELATIVE_DOC_LINK = %r{\]\((\.\./[^)\s]+)\)}

  Error = Class.new(StandardError)

  Feature = Struct.new(:path, :metadata, :body)

  # Dumps as [Free, Premium, Ultimate] rather than as a block list, to match
  # the hand-written What's New files.
  class InlineArray < Array
    def encode_with(coder)
      coder.represent_seq(nil, self)
      coder.style = Psych::Nodes::Sequence::FLOW
    end
  end

  # Dumps as a `|` block rather than a folded or escaped scalar, which Psych would otherwise
  # pick for a single-paragraph description. Emits a redundant `!` tag that #dump_entries strips.
  class BlockString < String
    def encode_with(coder)
      coder.represent_scalar(nil, to_s)
      coder.style = Psych::Nodes::Scalar::LITERAL
    end
  end

  # `today` is injected so the release window can be exercised from specs and from
  # a local run, without waiting for an actual release week.
  def initialize(
    whats_new_template_path:,
    release_url: RELEASES_YML_URL,
    force: false,
    today: Date.today # rubocop:disable Rails/Date -- Standalone script, Rails' Time.zone is not loaded
  )
    @whats_new_template_path = whats_new_template_path.to_s
    @release_url = release_url
    @force = force
    @today = today

    raise ArgumentError, "What's New template not found: #{@whats_new_template_path}" \
      unless File.exist?(@whats_new_template_path)
  end

  def generate
    release = current_release(fetch_releases)
    # Outside release week there is nothing to publish, so the scheduled job is a no-op
    unless release
      puts no_release_message
      return
    end

    version = release['version']

    info "Forced run: nearest release is #{version} (#{release['date']})" if force

    features = features(version)
    # If no feature files found, we do not need to generate a new what's new file
    if features.empty?
      puts "No feature files found for release #{version}. No What's New file will be generated."
      return
    end

    # Generate the new what's new YAML file
    directory = File.join(ROOT, 'data', 'whats_new')

    release_date = [release]
    formatted_release_date = release['date'].to_s.delete('-')
    # Prepend 0 to minor if version is < 10 to match the filename format
    major, minor = version.split('.')
    formatted_version = "#{major}_#{minor.rjust(2, '0')}"

    filename = "#{formatted_release_date}0001_#{formatted_version}.yml"

    file_path = File.join(directory, filename)

    template = YAML.load_file(whats_new_template_path)
    all_entries = []

    # Build new entries for each feature
    features.each do |feature|
      # Omit image_url from the template
      new_entry = template.first.except('image_url')
      build_whats_new_entry(new_entry, feature, release_date, version)
      all_entries << new_entry
    end

    File.write(file_path, dump_entries(all_entries))

    info "Successfully created latest What's New file: #{file_path}"
  end

  private

  attr_reader :whats_new_path, :whats_new_template_path, :release_url, :force, :today

  def info(text)
    puts "[#{self.class.name}] #{text}"
  end

  def no_release_message
    return "No dated releases found in #{release_url}. No What's New file will be generated." if force

    "No release scheduled for #{today}. No What's New file will be generated."
  end

  def fetch_releases
    YAML.safe_load(releases_yaml)
  end

  def releases_yaml
    return File.read(release_url) unless release_url.start_with?('http')

    response = Net::HTTP.get_response(URI.parse(release_url))

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Failed to fetch #{release_url}: #{response.code} #{response.message}"
    end

    response.body
  end

  # Return release info if today's date matches a date in releases.yml.
  # A forced run has no release-day guarantee, so it takes whichever release sits
  # closest to today; equidistant dates resolve to the upcoming one.
  def current_release(releases)
    dated = releases.select { |release| release['date'] }

    return dated.find { |release| Date.parse(release['date'].to_s) == today } unless force

    dated.min_by do |release|
      date = Date.parse(release['date'].to_s)
      [(date - today).abs, date < today ? 1 : 0]
    end
  end

  def features(version)
    # Data to find the right release folder under doc/releases
    major_version = version.split('.')[0]
    formatted_hyphenated_version = version.tr('.', '-')
    release_folder = File.join(ROOT, "doc/releases/#{major_version}/gitlab-#{formatted_hyphenated_version}-released")

    features = []

    Dir.glob("#{release_folder}/**/*.md").each do |file_path|
      # Ignore index.md - they are not feature files
      next if File.basename(file_path) == 'index.md'

      begin
        metadata, body = extract_frontmatter(file_path)

        features << Feature.new(file_path, metadata, body)
      rescue StandardError => e
        puts "Error processing frontmatter in #{file_path}: #{e.message}"
      end
    end

    sort_features(features)
  end

  def extract_frontmatter(file_path)
    file_content = File.read(file_path)

    if file_content =~ /\A---(.*?)^---\s*\n(.*)/m
      frontmatter_string = ::Regexp.last_match(1)
      content_body = ::Regexp.last_match(2)

      data = YAML.safe_load(frontmatter_string) || {}

      [data, content_body]
    else
      [{}, file_content]
    end
  end

  def sort_features(features)
    features.sort_by do |feature|
      weight = feature.metadata['weight']
      level = feature.metadata['level'].to_s

      [
        level == 'primary' ? 0 : 1,
        weight.nil? ? 1 : 0,
        weight || 0,
        File.basename(feature.path)
      ]
    end
  end

  def build_whats_new_entry(new_entry, feature, release_date, version)
    metadata = feature.metadata

    # Fill in the data matching your template structure
    new_entry['name'] = metadata['title']
    new_entry['description'] = block_scalar_body(absolute_doc_links(feature.body))
    new_entry['stage'] = metadata['stage']
    new_entry['self-managed'] = self_managed?(metadata['offering'])
    new_entry['gitlab-com'] = gitlab_com?(metadata['offering'])
    new_entry['available_in'] = InlineArray[*Array(metadata['tier'])]
    new_entry['documentation_link'] = docs_url(metadata['documentation_link'])
    new_entry['published_at'] = Date.parse(release_date[0]['date'].to_s)
    new_entry['release'] = version

    new_entry
  end

  def dump_entries(entries)
    YAML.dump(entries)
      .delete_prefix("---\n")
      # Double quote the release version, drop the tag BlockString emits, and separate
      # each entry with a blank line
      .gsub(/^(\s*release:) '(.+)'$/, '\1 "\2"')
      .gsub(/^(\s*(?:- )?description:) ! \|/, '\1 |')
      .gsub(/\n(?=- )/, "\n\n")
  end

  def block_scalar_body(body)
    BlockString.new("#{body.lines.map(&:rstrip).join("\n").strip}\n")
  end

  # Feature docs link to each other with repository-relative paths, but What's New
  # renders outside the docs site, so those links have to be absolute.
  def absolute_doc_links(body)
    body.gsub(RELATIVE_DOC_LINK) { "](#{docs_url(::Regexp.last_match(1))})" }
  end

  def self_managed?(offerings)
    offerings.include?('self_managed')
  end

  def gitlab_com?(offerings)
    offerings.include?('gitlab_com')
  end

  def docs_url(link)
    return link if link.start_with?("http")

    # Hugo serves doc/foo/bar.md at /foo/bar/ and doc/foo/_index.md at /foo/
    path = link.sub(%r{\A(\.\./)+}, "").sub(%r{(?:/_index)?\.md(?=#|\z)}, "/")

    "#{DOCS_BASE_URL}#{path}"
  end
end

if __FILE__ == $PROGRAM_NAME
  whats_new_template_path = File.join(
    UpdateWhatsNewContent::ROOT,
    'data',
    'whats_new',
    'templates',
    'YYYYMMDD0001_XX_YY.yml'
  )

  # Allow the date to be overridden for local testing, otherwise use today's date
  # rubocop:disable Rails/Date -- Standalone script, Rails' Time.zone is not loaded
  today = ENV['WHATS_NEW_TODAY'] ? Date.parse(ENV['WHATS_NEW_TODAY']) : Date.today
  # rubocop:enable Rails/Date

  force = %w[true 1].include?(ENV['WHATS_NEW_FORCE'].to_s.downcase)

  updater = UpdateWhatsNewContent.new(
    whats_new_template_path: whats_new_template_path,
    today: today,
    force: force
  )

  updater.generate
end
