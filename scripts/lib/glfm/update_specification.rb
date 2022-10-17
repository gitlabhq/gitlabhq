# frozen_string_literal: true
require 'fileutils'
require 'open-uri'
require 'pathname'
require_relative 'constants'
require_relative 'shared'

module Glfm
  class UpdateSpecification
    include Constants
    include Shared

    def process
      output('Updating specification...')
      ghfm_spec_lines = load_ghfm_spec
      glfm_spec_txt_string = build_glfm_spec_txt(ghfm_spec_lines)
      write_glfm_spec_txt(glfm_spec_txt_string)
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
      ghfm_spec_txt_uri_io = URI.parse(GHFM_SPEC_TXT_URI).open

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
  end
end
