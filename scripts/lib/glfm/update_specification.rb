# frozen_string_literal: true
require 'fileutils'
require 'open-uri'
require 'pathname'
require 'tempfile'
require 'yaml'
require_relative 'constants'
require_relative 'shared'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#update-specificationrb-script
# for details on the implementation and usage of this script. This developers guide
# contains diagrams and documentation of this script,
# including explanations and examples of all files it reads and writes.
#
# Also note that this script is intentionally written in a pure-functional (not OO) style,
# with no dependencies on Rails or the GitLab libraries. These choices are intended to make
# it faster and easier to test and debug.
module Glfm
  class UpdateSpecification
    include Constants
    include Shared

    def process(skip_spec_html_generation: false)
      output('Updating specification...')

      ghfm_spec_lines = load_ghfm_spec
      glfm_spec_txt_string = build_glfm_spec_txt(ghfm_spec_lines)
      write_glfm_spec_txt(glfm_spec_txt_string)

      if skip_spec_html_generation
        output("Skipping GLFM spec.html generation...")
        return
      end

      glfm_spec_html_string = generate_glfm_spec_html(glfm_spec_txt_string)
      write_glfm_spec_html(glfm_spec_html_string)
    end

    private

    def load_ghfm_spec
      # We only re-download the GitHub Flavored Markdown specification if the
      # UPDATE_GHFM_SPEC_MD environment variable is set to true, which should only
      # ever be done manually and locally, never in CI. This provides some security
      # protection against a possible injection attack vector, if the GitHub-hosted
      # version of the spec is ever temporarily compromised with an injection attack.
      #
      # This also avoids doing external network access to download the file
      # in CI jobs, which can avoid potentially flaky builds if the GitHub-hosted
      # version of the file is temporarily unavailable.
      if ENV['UPDATE_GHFM_SPEC_MD'] == 'true'
        update_ghfm_spec_md
      else
        read_existing_ghfm_spec_md
      end
    end

    def read_existing_ghfm_spec_md
      output("Reading existing #{GHFM_SPEC_MD_PATH}...")
      File.open(GHFM_SPEC_MD_PATH).readlines
    end

    def update_ghfm_spec_md
      output("Downloading #{GHFM_SPEC_TXT_URI}...")
      # NOTE: We use `URI.parse` to avoid RuboCop warning "Security/Open",
      #       even though we are using a trusted URI from a string literal constant.
      #       See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98656#note_1138595002 for details.
      ghfm_spec_txt_uri_parsed = URI.parse(GHFM_SPEC_TXT_URI)
      ghfm_spec_txt_uri_io = ghfm_spec_txt_uri_parsed.open

      # Read IO stream into an array of lines for easy processing later
      ghfm_spec_lines = ghfm_spec_txt_uri_io.readlines
      raise "Unable to read lines from #{GHFM_SPEC_TXT_URI}" if ghfm_spec_lines.empty?

      # Make sure the GHFM spec version has not changed
      validate_expected_spec_version!(ghfm_spec_lines[2])

      # Reset IO stream and re-read into a single string for easy writing
      # noinspection RubyNilAnalysis
      ghfm_spec_txt_uri_io.seek(0)
      ghfm_spec_string = ghfm_spec_txt_uri_io.read
      raise "Unable to read string from #{GHFM_SPEC_TXT_URI}" unless ghfm_spec_string

      output("Writing #{GHFM_SPEC_MD_PATH}...")
      GHFM_SPEC_MD_PATH.dirname.mkpath
      write_file(GHFM_SPEC_MD_PATH, ghfm_spec_string)

      ghfm_spec_lines
    end

    def validate_expected_spec_version!(version_line)
      return if version_line =~ /\Aversion: #{GHFM_SPEC_VERSION}\Z/o

      raise "GitHub Flavored Markdown spec.txt version mismatch! " \
          "Expected 'version: #{GHFM_SPEC_VERSION}', got '#{version_line}'"
    end

    def build_glfm_spec_txt(ghfm_spec_txt_lines)
      glfm_spec_txt_lines = ghfm_spec_txt_lines.dup
      replace_header(glfm_spec_txt_lines)
      replace_intro_section(glfm_spec_txt_lines)
      insert_examples(glfm_spec_txt_lines)
      glfm_spec_txt_lines.join('')
    end

    def replace_header(spec_txt_lines)
      spec_txt_lines[0, spec_txt_lines.index("...\n") + 1] = GLFM_SPEC_TXT_HEADER
    end

    def replace_intro_section(spec_txt_lines)
      glfm_intro_md_lines = File.open(GLFM_INTRO_MD_PATH).readlines
      raise "Unable to read lines from #{GLFM_INTRO_MD_PATH}" if glfm_intro_md_lines.empty?

      ghfm_intro_header_begin_index = spec_txt_lines.index do |line|
        line =~ INTRODUCTION_HEADER_LINE_TEXT
      end
      raise "Unable to locate introduction header line in #{GHFM_SPEC_MD_PATH}" if ghfm_intro_header_begin_index.nil?

      # Find the index of the next header after the introduction header, starting from the index
      # of the introduction header this is the length of the intro section
      ghfm_intro_section_length = spec_txt_lines[ghfm_intro_header_begin_index + 1..].index do |line|
        line.start_with?('# ')
      end

      # Replace the intro section with the GitLab flavored Markdown intro section
      spec_txt_lines[ghfm_intro_header_begin_index, ghfm_intro_section_length] = glfm_intro_md_lines
    end

    def insert_examples(spec_txt_lines)
      official_spec_lines = File.open(GLFM_OFFICIAL_SPECIFICATION_EXAMPLES_MD_PATH).readlines
      raise "Unable to read lines from #{GLFM_OFFICIAL_SPECIFICATION_EXAMPLES_MD_PATH}" if official_spec_lines.empty?

      internal_extension_lines = File.open(GLFM_INTERNAL_EXTENSION_EXAMPLES_MD_PATH).readlines
      raise "Unable to read lines from #{GLFM_INTERNAL_EXTENSION_EXAMPLES_MD_PATH}" if internal_extension_lines.empty?

      ghfm_end_tests_comment_index = spec_txt_lines.index do |line|
        line =~ END_TESTS_COMMENT_LINE_TEXT
      end
      raise "Unable to locate 'END TESTS' comment line in #{GHFM_SPEC_MD_PATH}" if ghfm_end_tests_comment_index.nil?

      # Insert the GLFM examples before the 'END TESTS' comment line
      spec_txt_lines[ghfm_end_tests_comment_index - 1] = [
        "\n",
        official_spec_lines,
        "\n",
        internal_extension_lines,
        "\n"
      ].flatten

      spec_txt_lines
    end

    def write_glfm_spec_txt(glfm_spec_txt_string)
      output("Writing #{GLFM_SPEC_TXT_PATH}...")
      FileUtils.mkdir_p(Pathname.new(GLFM_SPEC_TXT_PATH).dirname)
      write_file(GLFM_SPEC_TXT_PATH, glfm_spec_txt_string)
    end

    def generate_glfm_spec_html(glfm_spec_txt_string)
      output("Generating spec.html from spec.txt markdown...")

      input_markdown_yml_string = <<~MARKDOWN
        ---
        spec_txt: |
        #{glfm_spec_txt_string.gsub(/^/, '  ')}
      MARKDOWN

      # NOTE: We must copy the input YAML file used by the `render_static_html.rb`
      # to a separate temporary file in order for the script to read them, because it is run in
      # a separate subprocess, and during unit testing we are unable to substitute the mock
      # StringIO when reading the input files in the subprocess.
      ENV['INPUT_MARKDOWN_YML_PATH'] = Dir::Tmpname.create(MARKDOWN_TEMPFILE_BASENAME) do |path|
        write_file(path, input_markdown_yml_string)
      end

      # NOTE 1: We shell out to perform the conversion of markdown to static HTML by invoking a
      # separate subprocess. This allows us to avoid using the Rails API or environment in this
      # script, which makes developing and running the unit tests for this script much faster,
      # because they can use 'fast_spec_helper' which does not require the entire Rails environment.

      # NOTE 2: We run this as an RSpec process, for the same reasons we run via Jest process below:
      # because that's the easiest way to ensure a reliable, fully-configured environment in which
      # to execute the markdown-processing logic. Also, in the static/backend case.

      # Dir::Tmpname.create requires a block, but we are using the non-block form to get the path
      # via the return value, so we pass an empty block to avoid an error.
      static_html_tempfile_path = Dir::Tmpname.create(STATIC_HTML_TEMPFILE_BASENAME) {}
      ENV['OUTPUT_STATIC_HTML_TEMPFILE_PATH'] = static_html_tempfile_path

      cmd = %(bin/rspec #{__dir__}/render_static_html.rb)
      run_external_cmd(cmd)

      output("Reading generated spec.html from tempfile #{static_html_tempfile_path}...")
      YAML.safe_load(File.open(static_html_tempfile_path), symbolize_names: true).fetch(:spec_txt)
    end

    def write_glfm_spec_html(glfm_spec_html_string)
      output("Writing #{GLFM_SPEC_TXT_PATH}...")
      FileUtils.mkdir_p(Pathname.new(GLFM_SPEC_HTML_PATH).dirname)
      write_file(GLFM_SPEC_HTML_PATH, "#{glfm_spec_html_string}\n")
    end
  end
end
