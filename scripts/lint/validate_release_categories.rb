# frozen_string_literal: true

# Validates category tags in GitLab release notes files.
#
# Requirements:
#   - After release 19.1: Every file MUST declare a non-empty `categories:` field in its YAML frontmatter.
#   - Before release 19.1: All H3 headings MUST have a <!-- categories: ... --> tag.
# In both cases the category names are validated against categories.yml.
#
# Usage:
#   ruby ./scripts/lint/validate_release_categories.rb \
#     --release-notes doc/releases/19/gitlab-19-0-released.md \
#     --categories-url https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/categories.yml

require 'optparse'
require 'open-uri'
require 'yaml'
require 'date'

module Lint
  class ValidateReleaseCategories
    CATEGORIES_URL = 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/categories.yml'

    # Matches <!-- categories: Foo, Bar, Baz -->
    CATEGORY_COMMENT_RE = /<!--\s*categories:\s*(.+?)\s*-->/

    # Matches `name: 'Some Category'` or `name: "Some Category"` or `name: Some Category`
    CATEGORY_NAME_RE = /^\s{2}name:\s*['"]?(.+?)['"]?\s*$/

    # 1MB limit to prevent memory exhaustion from unexpectedly large responses
    MAX_RESPONSE_BYTES = 1024 * 1024

    attr_reader :release_notes, :categories_url

    def self.parse_options(argv)
      options = { categories_url: CATEGORIES_URL, release_notes: [] }

      parser = OptionParser.new do |opts|
        opts.banner = 'Validate release note category tags against categories.yml.'

        opts.on('--release-notes FILE', 'Path(s) to the release notes markdown file(s)') do |file|
          options[:release_notes] << file
        end

        opts.on('--categories-url URL', 'Raw HTTPS URL to categories.yml') do |url|
          options[:categories_url] = url
        end
      end

      # nargs="+" equivalent: --release-notes takes the first path, and any
      # remaining positional args (e.g. from a shell glob) are swept up too.
      options[:release_notes].concat(parser.parse!(argv))

      if options[:release_notes].empty?
        warn parser.help
        warn 'error: --release-notes is required'
        exit 2
      end

      options
    end

    def initialize(release_notes: [], categories_url: CATEGORIES_URL)
      @release_notes = release_notes
      @categories_url = categories_url
    end

    # Returns true when every file passed validation, false otherwise.
    def run
      valid_names = load_valid_names(categories_url)

      file_paths = expand_file_paths(release_notes)
      all_errors, files_processed, files_with_errors = validate_files(file_paths, valid_names)

      puts "Processed #{files_processed} file(s)"

      unless all_errors.empty?
        puts "\n#{files_with_errors} file(s) had validation errors:\n\n"
        all_errors.each { |error| puts error }
        puts "Valid category names:\n  #{valid_names.sort.join("\n  ")}"
        return false
      end

      puts "All #{files_processed} file(s) passed validation."
      true
    end

    private

    def fetch_valid_category_names(url)
      raise ArgumentError, "URL must use HTTPS: #{url}" unless url.start_with?('https://')

      # Read one byte past the limit so we can detect an oversized response
      content = URI.parse(url).open(read_timeout: 30) { |io| io.read(MAX_RESPONSE_BYTES + 1) }

      raise ArgumentError, 'Response exceeded 1MB limit' if content && content.bytesize > MAX_RESPONSE_BYTES

      Set.new(content.to_s.scan(CATEGORY_NAME_RE).flatten)
    end

    # Parse the YAML frontmatter block (delimited by the leading `---` lines).
    # Returns a Hash, or {} when there is no frontmatter or it can't be parsed.
    def parse_frontmatter(content)
      match = content.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n/m)
      return {} unless match

      YAML.safe_load(match[1], permitted_classes: [Date]) || {}
    rescue Psych::Exception
      {}
    end

    # Append CASE MISMATCH / UNKNOWN errors for any category name not in categories.yml.
    # `context` is the location label shown in the error (e.g. "frontmatter" or "### Heading").
    def check_category_names(categories, context, valid_names, lower_map, errors)
      categories.each do |cat|
        next if valid_names.include?(cat)

        errors << if lower_map.key?(cat.downcase)
                    "CASE MISMATCH | #{context} | '#{cat}' should be '#{lower_map[cat.downcase]}'"
                  else
                    "UNKNOWN | #{context} | '#{cat}' not found in categories.yml"
                  end
      end
    end

    # Returns an array of [heading, categories] pairs for every H3 in the given content.
    # - heading: the H3 heading text.
    # - categories: nil if no tag was found, or an array of category name strings if found.
    def parse_release_notes(content)
      # Remove feature addition template comment blocks entirely before parsing
      content = content.gsub(/<!--\s*Copy this template.*?-->/m, '')

      results = []

      # Split on H2 and H3 headings, keeping the heading lines as tokens
      sections = content.split(/^(\#{2,3} .+)$/)

      i = 1
      while i < sections.length - 1
        heading_line = sections[i].strip
        body = sections[i + 1]

        if heading_line.start_with?('### ')
          heading = heading_line.delete_prefix('### ').strip

          # Only search for the category tag before the {{< details >}} block
          # to enforce that it stays co-located with the heading
          before_details = body.split('{{< details >}}', 2).first

          match = before_details.match(CATEGORY_COMMENT_RE)

          categories = match && match[1].split(',').map(&:strip).reject(&:empty?)

          results << [heading, categories]
        end

        i += 2
      end

      results
    end

    # Read a release note file. Returns the content string, or a [false, errors]
    # tuple when the file can't be read.
    def read_release_note(file_path)
      File.read(file_path, encoding: 'UTF-8')
    rescue Errno::ENOENT
      [false, ["File not found: #{file_path}"]]
    rescue StandardError => e
      [false, ["Error reading #{file_path}: #{e}"]]
    end

    # Check 1: Frontmatter categories (new leaf bundle format).
    # Returns an errors array if this format applies, or nil if it doesn't.
    def check_frontmatter_categories(content, valid_names, lower_map)
      frontmatter = parse_frontmatter(content)
      categories = Array(frontmatter['categories']).map { |cat| cat.to_s.strip }.reject(&:empty?)
      return if categories.empty?

      errors = []
      check_category_names(categories, 'In frontmatter', valid_names, lower_map, errors)
      errors
    end

    # Check 2: H3 inline category tags (old aggregated format).
    # Returns an errors array if this format applies, or nil if it doesn't.
    def check_h3_categories(content, valid_names, lower_map)
      features = parse_release_notes(content)
      tagged = features.reject { |_heading, cats| cats.nil? }
      return if tagged.empty?

      errors = []
      errors.concat(
        features.select { |_heading, cats| cats.nil? }.map do |heading, _cats|
          "MISSING TAG | ### #{heading} | All features must have a category"
        end
      )

      tagged.each do |heading, categories|
        check_category_names(categories, "At ### #{heading}", valid_names, lower_map, errors)
      end
      errors
    end

    # Check 3: Leaf bundle format - category comment in body without H3 heading.
    # Returns an errors array if this format applies, or nil if it doesn't.
    def check_body_comment_categories(content, valid_names, lower_map)
      body_match = content.match(CATEGORY_COMMENT_RE)
      return unless body_match

      categories = body_match[1].split(',').map(&:strip).reject(&:empty?)
      errors = []
      check_category_names(categories, 'In body comment', valid_names, lower_map, errors)
      errors
    end

    # Validate a single release note file and return [success, errors].
    def validate_file(file_path, valid_names)
      content = read_release_note(file_path)
      return content unless content.is_a?(String)

      lower_map = valid_names.each_with_object({}) { |name, h| h[name.downcase] = name } # rubocop:disable Rails/IndexBy -- This script does not depend on ActiveSupport.

      errors = check_frontmatter_categories(content, valid_names, lower_map) ||
        check_h3_categories(content, valid_names, lower_map) ||
        check_body_comment_categories(content, valid_names, lower_map) ||
        ["MISSING | In file | Missing 'categories' field (expected in frontmatter or body)"]

      [errors.empty?, errors]
    end

    def load_valid_names(categories_url)
      puts "Fetching categories from #{categories_url} ...\n\n"

      valid_names = fetch_valid_category_names(categories_url)

      puts "#{valid_names.size} valid category names loaded.\n\n"
      valid_names
    rescue OpenURI::HTTPError, SocketError, OpenSSL::SSL::SSLError, Net::OpenTimeout,
      Net::ReadTimeout, ArgumentError => e
      puts "Failed to fetch or parse categories.yml: #{e}"
      exit 2
    end

    # Expand directories into their contained markdown files, skipping files that
    # do not carry categories (index.md/_index.md and upcoming.md).
    def expand_file_paths(release_notes)
      paths = release_notes.flat_map do |file_path|
        File.directory?(file_path) ? Dir.glob("#{file_path}/**/*.md") : [file_path]
      end

      paths.uniq.reject do |file_path|
        file_path.end_with?("index.md") || File.basename(file_path) == "upcoming.md"
      end
    end

    # Validate every file and return [all_errors, files_processed, files_with_errors].
    def validate_files(file_paths, valid_names)
      all_errors = []
      files_with_errors = 0

      file_paths.each do |file_path|
        puts "Validating #{file_path} ..."
        success, errors = validate_file(file_path, valid_names)

        next if success && errors.empty?

        files_with_errors += 1
        all_errors.concat(["In #{file_path}:"] + errors + [''])
      end

      [all_errors, file_paths.size, files_with_errors]
    end
  end
end

# Run the script if executed directly
if $PROGRAM_NAME == __FILE__
  options = Lint::ValidateReleaseCategories.parse_options(ARGV)
  linter = Lint::ValidateReleaseCategories.new(**options)
  exit(linter.run ? 0 : 1)
end
