# frozen_string_literal: true
require 'fileutils'
require 'open-uri'
require 'yaml'
require 'psych'
require 'tempfile'
require 'open3'
require_relative 'constants'
require_relative 'shared'
require_relative 'parse_examples'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/
# for details on the implementation and usage of this script. This developers guide
# contains diagrams and documentation of this script,
# including explanations and examples of all files it reads and writes.
#
# Also note that this script is intentionally written in a pure-functional (not OO) style,
# with no dependencies on Rails or the GitLab libraries. These choices are intended to make
# it faster and easier to test and debug.
module Glfm
  class UpdateExampleSnapshots
    include Constants
    include Shared
    include ParseExamples

    # skip_static_and_wysiwyg can be used to skip the backend/frontend html and prosemirror JSON
    # generation which depends on external calls. This allows for faster processing in unit tests
    # which do not require it.
    def process(skip_static_and_wysiwyg: false)
      output('Updating example snapshots...')

      setup_environment

      output('(Skipping static HTML generation)') if skip_static_and_wysiwyg

      output("Reading #{GLFM_SPEC_TXT_PATH}...")
      glfm_spec_txt_lines = File.open(GLFM_SPEC_TXT_PATH).readlines

      # Parse all the examples from `spec.txt`, using a Ruby port of the Python `get_tests`
      # function the from original CommonMark/GFM `spec_test.py` script.
      all_examples = parse_examples(glfm_spec_txt_lines)

      add_example_names(all_examples)

      reject_disabled_examples(all_examples)

      write_snapshot_example_files(all_examples, skip_static_and_wysiwyg: skip_static_and_wysiwyg)
    end

    private

    def setup_environment
      # Set 'GITLAB_TEST_FOOTNOTE_ID' in order to override random number generation in
      # Banzai::Filter::FootnoteFilter#random_number, and thus avoid the need to
      # perform normalization on the value. See:
      # https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#normalization
      ENV['GITLAB_TEST_FOOTNOTE_ID'] = '42'
    end

    def add_example_names(all_examples)
      # NOTE: This method and the parse_examples method assume:
      # 1. Section 2 is the first section which contains examples
      # 2. Examples are always nested exactly 2 levels deep in an H2
      # 3. There may exist H3 headings with no examples (e.g. "Motivation" in the GLFM spec.txt)
      # 4. The Appendix doesn't ever contain any examples, so it doesn't show up
      #    in the H1 header count. So, even though due to the concatenation it appears before the
      #    GitLab examples sections, it doesn't result in their header counts being off by +1.
      # 5. If an example contains the 'disabled' string extension, it is skipped (and will thus
      #    result in a skip in the `spec_txt_example_position`). This behavior is taken from the
      #    GFM `spec_test.py` script (but it's NOT in the original CommonMark `spec_test.py`).
      # 6. If a section contains ONLY disabled examples, the section numbering will still be
      #    incremented to match the rendered HTML specification section numbering.
      # 7. Every H2 must contain at least one example, but it is allowed that they are all disabled.

      h1_count = 1 # examples start in H1 section 2; section 1 is the overview with no examples.
      h2_count = 0
      previous_h1 = ''
      previous_h2 = ''
      index_within_h2 = 0
      all_examples.each do |example|
        headers = example[:headers]

        if headers[0] != previous_h1
          h1_count += 1
          h2_count = 0
          previous_h1 = headers[0]
        end

        if headers[1] != previous_h2
          h2_count += 1
          previous_h2 = headers[1]
          index_within_h2 = 0
        end

        index_within_h2 += 1

        # convert headers array to lowercase string with underscores, and double underscores between headers
        formatted_headers_text = headers.join('__').tr('-', '_').tr(' ', '_').downcase

        hierarchy_level = "#{h1_count.to_s.rjust(2, '0')}_#{h2_count.to_s.rjust(2, '0')}"
        position_within_section = index_within_h2.to_s.rjust(3, '0')
        name = "#{hierarchy_level}__#{formatted_headers_text}__#{position_within_section}"
        converted_name = name.tr('(', '').tr(')', '') # remove any parens from the name
        example[:name] = converted_name
      end
    end

    def reject_disabled_examples(all_examples)
      all_examples.reject! { |example| example[:disabled] }
    end

    def write_snapshot_example_files(all_examples, skip_static_and_wysiwyg:)
      output("Reading #{GLFM_EXAMPLE_STATUS_YML_PATH}...")
      glfm_examples_statuses = YAML.safe_load(File.open(GLFM_EXAMPLE_STATUS_YML_PATH))
      validate_glfm_example_status_yml(glfm_examples_statuses)

      write_examples_index_yml(all_examples)

      write_markdown_yml(all_examples)

      if skip_static_and_wysiwyg
        output("Skipping static/WYSIWYG HTML and prosemirror JSON generation...")
        return
      end

      markdown_yml_tempfile_path = write_markdown_yml_tempfile
      static_html_hash = generate_static_html(markdown_yml_tempfile_path)
      wysiwyg_html_and_json_hash = generate_wysiwyg_html_and_json(markdown_yml_tempfile_path)

      write_html_yml(all_examples, static_html_hash, wysiwyg_html_and_json_hash, glfm_examples_statuses)

      write_prosemirror_json_yml(all_examples, wysiwyg_html_and_json_hash, glfm_examples_statuses)
    end

    def validate_glfm_example_status_yml(glfm_examples_statuses)
      glfm_examples_statuses.each do |example_name, statuses|
        next unless statuses &&
          statuses['skip_update_example_snapshots'] &&
          statuses.any? { |key, value| key.include?('skip_update_example_snapshot_') && !!value }

        raise "Error: '#{example_name}' must not have any 'skip_update_example_snapshot_*' values specified " \
                "if 'skip_update_example_snapshots' is truthy"
      end
    end

    def write_examples_index_yml(all_examples)
      generate_and_write_for_all_examples(
        all_examples, ES_EXAMPLES_INDEX_YML_PATH, literal_scalars: false
      ) do |example, hash|
        hash[example.fetch(:name)] = {
          'spec_txt_example_position' => example.fetch(:example),
          'source_specification' =>
            if example[:extensions].empty?
              'commonmark'
            elsif example[:extensions].include?('gitlab')
              'gitlab'
            else
              'github'
            end
        }
      end
    end

    def write_markdown_yml(all_examples)
      generate_and_write_for_all_examples(all_examples, ES_MARKDOWN_YML_PATH) do |example, hash|
        hash[example.fetch(:name)] = example.fetch(:markdown)
      end
    end

    def write_markdown_yml_tempfile
      # NOTE: We must copy the markdown YAML file to a separate temporary file for the
      # `render_static_html.rb` script to read it, because the script is run in a
      # separate process, and during unit testing we are unable to substitute the mock
      # StringIO when reading the input file in the subprocess.
      Dir::Tmpname.create(MARKDOWN_TEMPFILE_BASENAME) do |path|
        io = File.open(ES_MARKDOWN_YML_PATH)
        io.seek(0) # rewind the file. This is necessary when testing with a mock StringIO
        contents = io.read
        write_file(path, contents)
      end
    end

    def generate_static_html(markdown_yml_tempfile_path)
      output("Generating static HTML from markdown examples...")

      # NOTE 1: We shell out to perform the conversion of markdown to static HTML via the internal Rails app
      # helper method. This allows us to avoid using the Rails API or environment in this script,
      # which makes developing and running the unit tests for this script much faster,
      # because they can use 'fast_spec_helper' which does not require the entire Rails environment.

      # NOTE 2: We pass the input file path as a command line argument, and receive the output
      # tempfile path as a return value. This is simplest in the case where we are invoking Ruby.
      cmd = %(rails runner #{__dir__}/render_static_html.rb #{markdown_yml_tempfile_path})
      cmd_output = run_external_cmd(cmd)
      # NOTE: Running under a debugger can add extra output, only take the last line
      static_html_tempfile_path = cmd_output.split("\n").last

      output("Reading generated static HTML from tempfile #{static_html_tempfile_path}...")
      YAML.load_file(static_html_tempfile_path)
    end

    def generate_wysiwyg_html_and_json(markdown_yml_tempfile_path)
      output("Generating WYSIWYG HTML and prosemirror JSON from markdown examples...")

      # NOTE: Unlike when we invoke a Ruby script, here we pass the input and output file paths
      # via environment variables. This is because it's not straightforward/clean to pass command line
      # arguments when we are invoking `yarn jest ...`
      ENV['INPUT_MARKDOWN_YML_PATH'] = markdown_yml_tempfile_path

      # Dir::Tmpname.create requires a block, but we are using the non-block form to get the path
      # via the return value, so we pass an empty block to avoid an error.
      wysiwyg_html_and_json_tempfile_path = Dir::Tmpname.create(WYSIWYG_HTML_AND_JSON_TEMPFILE_BASENAME) {}
      ENV['OUTPUT_WYSIWYG_HTML_AND_JSON_TEMPFILE_PATH'] = wysiwyg_html_and_json_tempfile_path

      cmd = %(yarn jest --testMatch '**/render_wysiwyg_html_and_json.js' #{__dir__}/render_wysiwyg_html_and_json.js)
      run_external_cmd(cmd)

      output("Reading generated WYSIWYG HTML and prosemirror JSON from tempfile " \
        "#{wysiwyg_html_and_json_tempfile_path}...")
      YAML.load_file(wysiwyg_html_and_json_tempfile_path)
    end

    def write_html_yml(all_examples, static_html_hash, wysiwyg_html_and_json_hash, glfm_examples_statuses)
      generate_and_write_for_all_examples(
        all_examples, ES_HTML_YML_PATH, glfm_examples_statuses
      ) do |example, hash, existing_hash|
        name = example.fetch(:name)
        example_statuses = glfm_examples_statuses[name] || {}

        static = if example_statuses['skip_update_example_snapshot_html_static']
                   existing_hash.dig(name, 'static')
                 else
                   static_html_hash[name]
                 end

        wysiwyg = if example_statuses['skip_update_example_snapshot_html_wysiwyg']
                    existing_hash.dig(name, 'wysiwyg')
                  else
                    wysiwyg_html_and_json_hash.dig(name, 'html')
                  end

        hash[name] = {
          'canonical' => example.fetch(:html),
          'static' => static,
          'wysiwyg' => wysiwyg
        }.compact # Do not assign nil values
      end
    end

    def write_prosemirror_json_yml(all_examples, wysiwyg_html_and_json_hash, glfm_examples_statuses)
      generate_and_write_for_all_examples(
        all_examples, ES_PROSEMIRROR_JSON_YML_PATH, glfm_examples_statuses
      ) do |example, hash, existing_hash|
        name = example.fetch(:name)

        json = if glfm_examples_statuses.dig(name, 'skip_update_example_snapshot_prosemirror_json')
                 existing_hash[name]
               else
                 wysiwyg_html_and_json_hash.dig(name, 'json')
               end

        # Do not assign nil values
        hash[name] = json if json
      end
    end

    def generate_and_write_for_all_examples(
      all_examples, output_file_path, glfm_examples_statuses = {}, literal_scalars: true
    )
      preserve_existing = !glfm_examples_statuses.empty?
      output("#{preserve_existing ? 'Creating/Updating' : 'Creating/Overwriting'} #{output_file_path}...")
      existing_hash = preserve_existing ? YAML.safe_load(File.open(output_file_path)) : {}

      output_hash = all_examples.each_with_object({}) do |example, hash|
        name = example.fetch(:name)
        if (reason = glfm_examples_statuses.dig(name, 'skip_update_example_snapshots'))
          # Output the reason for skipping the example, but only once, not multiple times for each file
          output("Skipping '#{name}'. Reason: #{reason}") unless glfm_examples_statuses.dig(name, :already_printed)
          # We just store the `:already_printed` flag in the hash entry itself. Then we
          # don't need an instance variable to keep the state, and this can remain a pure function ;)
          glfm_examples_statuses[name][:already_printed] = true

          # Copy over the existing example only if it exists and preserve_existing is true, otherwise omit this example
          # noinspection RubyScope
          hash[name] = existing_hash[name] if existing_hash[name]

          next
        end

        yield(example, hash, existing_hash)
      end

      yaml_string = dump_yaml_with_formatting(output_hash, literal_scalars: literal_scalars)
      write_file(output_file_path, yaml_string)
    end

    # Construct an AST so we can control YAML formatting for
    # YAML block scalar literals and key quoting.
    #
    # Note that when Psych dumps the markdown to YAML, it will
    # automatically use the default "clip" behavior of the Block Chomping Indicator (`|`)
    # https://yaml.org/spec/1.2.2/#8112-block-chomping-indicator,
    # when the markdown strings contain a trailing newline. The type of
    # Block Chomping Indicator is automatically determined, you cannot specify it
    # manually.
    def dump_yaml_with_formatting(hash, literal_scalars:)
      visitor = Psych::Visitors::YAMLTree.create
      visitor << hash
      ast = visitor.tree

      # Force all scalars to have literal formatting (using Block Chomping Indicator instead of quotes)
      if literal_scalars
        ast.grep(Psych::Nodes::Scalar).each do |node|
          node.style = Psych::Nodes::Scalar::LITERAL
        end
      end

      # Do not quote the keys
      ast.grep(Psych::Nodes::Mapping).each do |node|
        node.children.each_slice(2) do |k, _|
          k.quoted = false
          k.style = Psych::Nodes::Scalar::ANY
        end
      end

      ast.to_yaml
    end
  end
end
