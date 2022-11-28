# frozen_string_literal: true
require 'erb'
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

      # read and optionally update `input/github_flavored_markdown/ghfm_spec_v_x.yy.md`
      ghfm_spec_lines = load_ghfm_spec

      # create `output_spec/spec.txt`
      glfm_spec_txt_header_lines = GLFM_SPEC_TXT_HEADER.split("\n").map { |line| "#{line}\n" }
      official_spec_lines = readlines_from_path!(GLFM_OFFICIAL_SPECIFICATION_MD_PATH)
      glfm_spec_txt_string = (glfm_spec_txt_header_lines + official_spec_lines).join('')
      write_glfm_spec_txt(glfm_spec_txt_string)

      # create `output_example_snapshots/snapshot_spec.md`
      snapshot_spec_md_header_lines = ES_SNAPSHOT_SPEC_MD_HEADER.split("\n").map { |line| "#{line}\n" }
      ghfm_spec_example_lines = extract_ghfm_spec_example_lines(ghfm_spec_lines)
      official_spec_example_lines =
        extract_glfm_spec_example_lines(official_spec_lines, GLFM_OFFICIAL_SPECIFICATION_MD_PATH)
      internal_extension_lines = readlines_from_path!(GLFM_INTERNAL_EXTENSIONS_MD_PATH)
      validate_internal_extensions_md(internal_extension_lines)
      internal_extension_example_lines =
        extract_glfm_spec_example_lines(internal_extension_lines, GLFM_INTERNAL_EXTENSIONS_MD_PATH)

      snapshot_spec_md_string = (
        snapshot_spec_md_header_lines +
          ghfm_spec_example_lines +
          official_spec_example_lines +
          ["\n"] +
          internal_extension_example_lines
      ).join('')
      write_snapshot_spec_md(snapshot_spec_md_string)

      # Some unit tests can skip HTML generation if they don't need it, so they run faster
      if skip_spec_html_generation
        output("Skipping GLFM spec.html and snapshot_spec.html generation...")
        return
      end

      # Use the backend markdown processing to render un-styled GLFM specification HTML files from the markdown
      # We strip off the frontmatter headers before rendering.
      spec_html_unstyled_string, snapshot_spec_html_unstyled_string =
        generate_spec_html_files(
          glfm_spec_txt_string.gsub!(GLFM_SPEC_TXT_HEADER, "[TOC]\n\n"),
          snapshot_spec_md_string.gsub!(ES_SNAPSHOT_SPEC_MD_HEADER, "[TOC]\n\n"),
          ghfm_spec_example_lines.join('')
        )

      # Add styling to the rendered HTML files, to make them look like the CommonMark and
      # GitHub Flavored Markdown HTML-rendered specifications
      spec_html_styled_string = add_styling_to_specification_html(
        body: spec_html_unstyled_string,
        title: GLFM_SPEC_TXT_TITLE,
        version: GLFM_SPEC_VERSION
      )
      snapshot_spec_html_styled_string = add_styling_to_specification_html(
        body: snapshot_spec_html_unstyled_string,
        title: ES_SNAPSHOT_SPEC_TITLE,
        version: GLFM_SPEC_VERSION
      )

      # Write out the styled HTML GLFM specification HTML files
      write_spec_html(spec_html_styled_string)
      write_snapshot_spec_html(snapshot_spec_html_styled_string)
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

      ghfm_spec_lines = readlines_from_io!(ghfm_spec_txt_uri_io, GHFM_SPEC_TXT_URI)

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

    def extract_ghfm_spec_example_lines(spec_lines)
      # In the GHFM spec.txt format, all we have to identify the headers containing examples
      # is the presence of a single initial H1 named "Introduction" before the first
      # header containing examples, and the <!-- END TESTS --> comment after the last header
      # containing examples.
      path = GHFM_SPEC_MD_PATH
      first_examples_header_index = spec_lines.index do |line|
        line.start_with?('# ') && !line.start_with?(INTRODUCTION_HEADER_LINE_TEXT)
      end
      raise "Unable to find first examples header in #{path}" unless first_examples_header_index

      end_tests_comment_index = spec_lines.index do |line|
        line.start_with?(END_TESTS_COMMENT_LINE_TEXT)
      end
      raise "Unable to locate 'END TESTS' comment line in #{path}" if end_tests_comment_index.nil?

      spec_lines[first_examples_header_index..(end_tests_comment_index - 1)]
    end

    def extract_glfm_spec_example_lines(spec_lines, path)
      # In the GLFM input markdown files (unlike the GLFM spec.txt format), we have control over
      # the contents, so we can use explicit <!-- BEGIN TESTS --> and <!-- END TESTS -->
      # is the presence of a single initial H1 named "Introduction" before the first
      # header containing examples, and the <!-- END TESTS --> comment after the last header
      # containing examples.
      begin_tests_comment_line_index = spec_lines.index do |line|
        line.start_with?(BEGIN_TESTS_COMMENT_LINE_TEXT)
      end
      raise "Unable to locate 'BEGIN TESTS' comment line in #{path}" unless begin_tests_comment_line_index

      end_tests_comment_index = spec_lines.index do |line|
        line.start_with?(END_TESTS_COMMENT_LINE_TEXT)
      end
      raise "Unable to locate 'END TESTS' comment line in #{path}" if end_tests_comment_index.nil?

      spec_lines[(begin_tests_comment_line_index + 1)..(end_tests_comment_index - 1)]
    end

    def validate_internal_extensions_md(internal_extension_lines)
      first_line = internal_extension_lines[0].strip
      last_line = internal_extension_lines[-1].strip
      return unless first_line != BEGIN_TESTS_COMMENT_LINE_TEXT || last_line != END_TESTS_COMMENT_LINE_TEXT

      raise "Error: No content is allowed outside of the " \
            "'#{BEGIN_TESTS_COMMENT_LINE_TEXT}' and '#{END_TESTS_COMMENT_LINE_TEXT}' comments " \
              "in '#{GLFM_INTERNAL_EXTENSIONS_MD_PATH}'."
    end

    def write_glfm_spec_txt(glfm_spec_txt_string)
      output("Writing #{GLFM_SPEC_TXT_PATH}...")
      FileUtils.mkdir_p(Pathname.new(GLFM_SPEC_TXT_PATH).dirname)
      write_file(GLFM_SPEC_TXT_PATH, glfm_spec_txt_string)
    end

    def write_snapshot_spec_md(snapshot_spec_md_string)
      output("Writing #{ES_SNAPSHOT_SPEC_MD_PATH}...")
      FileUtils.mkdir_p(Pathname.new(ES_SNAPSHOT_SPEC_MD_PATH).dirname)
      write_file(ES_SNAPSHOT_SPEC_MD_PATH, snapshot_spec_md_string)
    end

    def generate_spec_html_files(spec_txt_string, snapshot_spec_md_string, ghfm_spec_examples_string)
      output("Generating spec.html and snapshot_spec.html from spec.txt and snapshot_spec.md markdown...")

      # NOTE: spec.txt only contains official GLFM examples, but snapshot_spec.md contains ALL examples, with the
      #       official GLFM examples coming _after_ the GHFM (which contains CommonMark + GHFM) examples, and the
      #       internal extension examples coming last. In the snapshot_spec.md, The CommonMark and GLFM examples come
      #       first, in order for the example numbers to match tne numbers in those separate specifications [1]. But, we
      #       also need for the numbering of the official examples in spec.txt to match the numbering of the official
      #       examples in snapshot_spec.md. Here's the ordering:
      #
      #       spec.txt:
      #       1. GLFM Official
      #
      #       snapshot_spec.md:
      #       1. GHFM (contains CommonMark + GHFM)
      #       2. GLFM Official
      #       3. GLFM Internal
      #
      #       [1] Note that the example numbering in the GLFM spec.html is currently out of sync with its corresponding
      #           spec.txt because its rendering is out of date. This has been reported in the following issue:
      #           https://github.com/github/cmark-gfm/issues/288
      ghfm_spec_examples_count = ghfm_spec_examples_string.scan(EXAMPLE_BEGIN_STRING).length

      spec_txt_string_split_examples =
        transform_examples_for_rendering(spec_txt_string, starting_example_number: ghfm_spec_examples_count + 1)
      snapshot_spec_md_string_split_examples = transform_examples_for_rendering(snapshot_spec_md_string)

      input_markdown_yml_string = <<~MARKDOWN
        ---
        spec_txt: |
        #{spec_txt_string_split_examples.gsub(/^/, '  ')}
        snapshot_spec_md: |
        #{snapshot_spec_md_string_split_examples.gsub(/^/, '  ')}
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

      output("Reading generated html from tempfile #{static_html_tempfile_path}...")
      rendered_html_hash = YAML.safe_load(File.open(static_html_tempfile_path), symbolize_names: true)
      [rendered_html_hash.fetch(:spec_txt), rendered_html_hash.fetch(:snapshot_spec_md)]
    end

    # NOTE: body, title, and version are used by the ERB binding.
    # noinspection RubyUnusedLocalVariable
    def add_styling_to_specification_html(body:, title:, version:)
      # noinspection RubyMismatchedArgumentType
      ERB.new(File.read(File.expand_path('specification_html_template.erb', __dir__))).result(binding)
    end

    def transform_examples_for_rendering(spec_md_string, starting_example_number: 1)
      # This method:
      # 1. Splits the single example code block which has a period between the markdown and HTML into two code blocks
      # 2. Adds a wrapper div for use in styling and target for the example number named anchor. This will get the
      #    'class="example" id="example-n"' attributes applied via javascript (since markdown rendering does not
      #    preserve classes or IDs)
      # 3. Adds a div which includes the example number named anchor and text. This will get the 'class="examplenum"'
      #    attribute applied via javascript.
      #
      # NOTE: Even though they will get stripped durning markdown rendering, we will go ahead and add the class and id
      #       attributes here, for easier debugging and comparison to the source markdown.
      example_replacement_regex = /(^#{EXAMPLE_BEGIN_STRING}.*?$(?:.|\n)*?)^\.$(\n(?:.|\n)*?^#{EXAMPLE_END_STRING}$)/mo
      example_num = starting_example_number
      spec_md_string.gsub(example_replacement_regex) do |_example_string|
        markdown_part = ::Regexp.last_match(1)
        html_part = ::Regexp.last_match(2)
        example_anchor_name = "example-#{example_num}"
        examplenum_div = %(<div class="examplenum"><a href="##{example_anchor_name}">Example #{example_num}</a></div>\n)
        example_num += 1
        # NOTE: We need blank lines before the markdown code blocks so they will be rendered properly
        %(<div class="example" id="#{example_anchor_name}">\n) +
          "#{examplenum_div}\n" \
          "#{markdown_part}" \
          "#{EXAMPLE_BACKTICKS_STRING}" \
          "\n\n" \
          "#{EXAMPLE_BACKTICKS_STRING}" \
          "#{html_part}\n" \
          '</div>'
      end
    end

    def write_spec_html(spec_html_string)
      output("Writing #{GLFM_SPEC_HTML_PATH}...")
      FileUtils.mkdir_p(Pathname.new(GLFM_SPEC_HTML_PATH).dirname)
      write_file(GLFM_SPEC_HTML_PATH, "#{spec_html_string}\n")
    end

    def write_snapshot_spec_html(snapshot_spec_html_string)
      output("Writing #{ES_SNAPSHOT_SPEC_HTML_PATH}...")
      FileUtils.mkdir_p(Pathname.new(ES_SNAPSHOT_SPEC_HTML_PATH).dirname)
      write_file(ES_SNAPSHOT_SPEC_HTML_PATH, "#{snapshot_spec_html_string}\n")
    end

    def readlines_from_path!(path)
      io = File.open(path)
      readlines_from_io!(io, path)
    end

    def readlines_from_io!(io, uri_or_path)
      lines = io.readlines
      raise "Unable to read lines from #{uri_or_path}" if lines.empty?

      lines
    end
  end
end
