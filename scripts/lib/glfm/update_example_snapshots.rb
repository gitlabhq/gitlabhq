# frozen_string_literal: true
require 'fileutils'
require 'open-uri'
require 'yaml'
require 'psych'
require 'tempfile'
require 'open3'
require 'active_support/core_ext/enumerable'
require_relative 'constants'
require_relative 'shared'
require_relative 'parse_examples'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#update-example-snapshotsrb-script
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

      output("Reading #{ES_SNAPSHOT_SPEC_MD_PATH}...")
      es_snapshot_spec_md_lines = File.open(ES_SNAPSHOT_SPEC_MD_PATH).readlines

      # Parse all the examples from `snapshot_spec.md`, using a Ruby port of the Python `get_tests`
      # function the from original CommonMark/GFM `spec_test.py` script.
      all_examples = parse_examples(es_snapshot_spec_md_lines)

      add_example_names(all_examples)

      reject_disabled_examples(all_examples)

      write_snapshot_example_files(all_examples, skip_static_and_wysiwyg: skip_static_and_wysiwyg)
    end

    private

    def add_example_names(all_examples)
      # NOTE: This method and the parse_examples method assume:
      # 1. Section 2 is the first section which contains examples
      # 2. Examples are always nested in an H2 or an H3, never directly in an H1
      # 3. There may exist headings with no examples (e.g. "Motivation" in the GLFM spec.txt)
      # 4. The Appendix doesn't ever contain any examples, so it doesn't show up
      #    in the H1 header count. So, even though due to the concatenation it appears before the
      #    GitLab examples sections, it doesn't result in their header counts being off by +1.
      # 5. If an example contains the 'disabled' string extension, it is skipped (and will thus
      #    result in a skip in the `spec_example_position`). This behavior is taken from the
      #    GFM `spec_test.py` script (but it's NOT in the original CommonMark `spec_test.py`).
      # 6. If a section contains ONLY disabled examples, the section numbering will still be
      #    incremented to match the rendered HTML specification section numbering.
      # 7. Every H2 or H3 must contain at least one example, but it is allowed that they are
      #    all disabled.

      h1_count = 1 # examples start in H1 section 2; section 1 is the overview with no examples.
      h2_count = 0
      h3_count = 0
      previous_h1 = ''
      previous_h2 = ''
      previous_h3 = ''
      index_within_current_heading = 0
      all_examples.each do |example|
        headers = example[:headers]

        if headers[0] != previous_h1
          h1_count += 1
          h2_count = 0
          h3_count = 0
          previous_h1 = headers[0]
        end

        if headers[1] != previous_h2
          h2_count += 1
          h3_count = 0
          previous_h2 = headers[1]
          index_within_current_heading = 0
        end

        if headers[2] && headers[2] != previous_h3
          h3_count += 1
          previous_h3 = headers[2]
          index_within_current_heading = 0
        end

        index_within_current_heading += 1

        # convert headers array to lowercase string with underscores, and double underscores between headers
        formatted_headers_text = headers.join('__').tr('-', '_').tr(' ', '_').downcase

        hierarchy_level =
          "#{h1_count.to_s.rjust(2, '0')}_" \
          "#{h2_count.to_s.rjust(2, '0')}_" \
          "#{h3_count.to_s.rjust(2, '0')}"
        position_within_section = index_within_current_heading.to_s.rjust(3, '0')
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
      glfm_examples_statuses = YAML.safe_load(File.open(GLFM_EXAMPLE_STATUS_YML_PATH), symbolize_names: true) || {}
      validate_glfm_example_status_yml(glfm_examples_statuses)

      write_examples_index_yml(all_examples)

      validate_glfm_config_file_example_names(all_examples)

      write_markdown_yml(all_examples)

      if skip_static_and_wysiwyg
        output("Skipping static/WYSIWYG HTML and prosemirror JSON generation...")
        return
      end

      # NOTE: We pass the INPUT_MARKDOWN_YML_PATH and INPUT_METADATA_YML_PATH via
      # environment variables to the static/wysiwyg HTML generation scripts. This is because they
      # are implemented as subprocesses which invoke rspec/jest scripts, and rspec/jest do not make
      # it straightforward to pass arguments via the command line.
      ENV['INPUT_MARKDOWN_YML_PATH'], ENV['INPUT_METADATA_YML_PATH'] = copy_tempfiles_for_subprocesses
      static_html_hash = generate_static_html
      wysiwyg_html_and_json_hash = generate_wysiwyg_html_and_json

      write_html_yml(all_examples, static_html_hash, wysiwyg_html_and_json_hash, glfm_examples_statuses)

      write_prosemirror_json_yml(all_examples, wysiwyg_html_and_json_hash, glfm_examples_statuses)
    end

    def validate_glfm_example_status_yml(glfm_examples_statuses)
      glfm_examples_statuses.each do |example_name, statuses|
        next unless statuses &&
          statuses[:skip_update_example_snapshots] &&
          statuses.any? { |key, value| key.to_s.include?('skip_update_example_snapshot_') && !!value }

        raise "Error: '#{example_name}' must not have any 'skip_update_example_snapshot_*' values specified " \
                "if 'skip_update_example_snapshots' is truthy"
      end
    end

    def validate_glfm_config_file_example_names(all_examples)
      valid_example_names = all_examples.pluck(:name).map(&:to_sym) # rubocop:disable CodeReuse/ActiveRecord

      # We are re-reading GLFM_EXAMPLE_STATUS_YML_PATH here, but that's OK, it's a small file, and rereading it
      # allows us to handle it in the same loop as the other manually-curated config files.
      [
        GLFM_EXAMPLE_STATUS_YML_PATH,
        GLFM_EXAMPLE_METADATA_YML_PATH,
        GLFM_EXAMPLE_NORMALIZATIONS_YML_PATH
      ].each do |path|
        output("Reading #{path}...")
        io = File.open(path)
        config_file_examples = YAML.safe_load(io, symbolize_names: true, aliases: true)

        # Skip validation if the config file is empty
        next unless config_file_examples

        config_file_example_names = config_file_examples.keys

        # Validate that all example names exist in the config file refer to an existing example in `examples_index.yml`,
        # unless it starts with the special prefix `00_`, which is preserved for usage as YAML anchors.
        invalid_name = config_file_example_names.detect do |name|
          !name.start_with?('00_') && valid_example_names.exclude?(name)
        end
        next unless invalid_name

        # NOTE: The extra spaces before punctuation in the error message allows for easier copy/pasting of the paths.
        err_msg =
          <<~TXT

            Error in input specification config file #{path} :

              Config file entry named #{invalid_name}
              does not have a corresponding example entry in
              #{ES_EXAMPLES_INDEX_YML_PATH} .

              Please delete or rename this config file entry.

              If this entry is being used as a YAML anchor, please rename it to start with '00_'.
          TXT
        raise err_msg
      end
    end

    def write_examples_index_yml(all_examples)
      generate_and_write_for_all_examples(
        all_examples, ES_EXAMPLES_INDEX_YML_PATH, literal_scalars: false
      ) do |example, hash|
        name = example.fetch(:name).to_sym
        hash[name] = {
          'spec_example_position' => example.fetch(:example),
          'source_specification' => source_specification_for_extensions(example.fetch(:extensions))
        }
      end
    end

    def source_specification_for_extensions(extensions)
      unprocessed_extensions = extensions.map(&:to_sym)
      unprocessed_extensions.delete(:disabled)

      source_specification =
        if unprocessed_extensions.empty?
          'commonmark'
        elsif unprocessed_extensions.include?(:gitlab)
          unprocessed_extensions.delete(:gitlab)
          'gitlab'
        else
          'github'
        end

      # We should only be left with at most one extension, which is an optional name for the example
      raise "Error: Invalid extension(s) found: #{unprocessed_extensions.join(', ')}" if unprocessed_extensions.size > 1

      source_specification
    end

    def write_markdown_yml(all_examples)
      generate_and_write_for_all_examples(all_examples, ES_MARKDOWN_YML_PATH) do |example, hash|
        name = example.fetch(:name).to_sym
        hash[name] = example.fetch(:markdown)
      end
    end

    def copy_tempfiles_for_subprocesses
      # NOTE: We must copy the input YAML files used by the `render_static_html.rb`
      # and `render_wysiwyg_html_and_json.js` scripts to a separate temporary file in order for
      # the scripts to read them, because the scripts are run in
      # separate subprocesses, and during unit testing we are unable to substitute the mock
      # StringIO when reading the input files in the subprocess.
      {
        ES_MARKDOWN_YML_PATH => MARKDOWN_TEMPFILE_BASENAME,
        GLFM_EXAMPLE_METADATA_YML_PATH => METADATA_TEMPFILE_BASENAME
      }.map do |original_file_path, tempfile_basename|
        Dir::Tmpname.create(tempfile_basename) do |path|
          io = File.open(original_file_path)
          io.seek(0) # rewind the file. This is necessary when testing with a mock StringIO
          contents = io.read
          write_file(path, contents)
        end
      end
    end

    def generate_static_html
      output("Generating static HTML from markdown examples...")

      # NOTE 1: We shell out to perform the conversion of markdown to static HTML by invoking a
      # separate subprocess. This allows us to avoid using the Rails API or environment in this
      # script, which makes developing and running the unit tests for this script much faster,
      # because they can use 'fast_spec_helper' which does not require the entire Rails environment.

      # NOTE 2: We run this as an RSpec process, for the same reasons we run via Jest process below:
      # because that's the easiest way to ensure a reliable, fully-configured environment in which
      # to execute the markdown-processing logic. Also, in the static/backend case, Rspec
      # provides the easiest and most reliable way to generate example data via Factorybot
      # creation of stable model records. This ensures consistent snapshot values across
      # machines/environments.

      # Dir::Tmpname.create requires a block, but we are using the non-block form to get the path
      # via the return value, so we pass an empty block to avoid an error.
      static_html_tempfile_path = Dir::Tmpname.create(STATIC_HTML_TEMPFILE_BASENAME) {}
      ENV['OUTPUT_STATIC_HTML_TEMPFILE_PATH'] = static_html_tempfile_path

      cmd = %(bin/rspec #{__dir__}/render_static_html.rb)
      run_external_cmd(cmd)

      output("Reading generated static HTML from tempfile #{static_html_tempfile_path}...")
      YAML.safe_load(File.open(static_html_tempfile_path), symbolize_names: true)
    end

    def generate_wysiwyg_html_and_json
      output("Generating WYSIWYG HTML and prosemirror JSON from markdown examples...")

      # Dir::Tmpname.create requires a block, but we are using the non-block form to get the path
      # via the return value, so we pass an empty block to avoid an error.
      wysiwyg_html_and_json_tempfile_path = Dir::Tmpname.create(WYSIWYG_HTML_AND_JSON_TEMPFILE_BASENAME) {}
      ENV['OUTPUT_WYSIWYG_HTML_AND_JSON_TEMPFILE_PATH'] = wysiwyg_html_and_json_tempfile_path

      cmd = "yarn jest:scripts #{__dir__}/render_wysiwyg_html_and_json.js"
      run_external_cmd(cmd)

      output("Reading generated WYSIWYG HTML and prosemirror JSON from tempfile " \
        "#{wysiwyg_html_and_json_tempfile_path}...")
      YAML.safe_load(File.open(wysiwyg_html_and_json_tempfile_path), symbolize_names: true)
    end

    def write_html_yml(all_examples, static_html_hash, wysiwyg_html_and_json_hash, glfm_examples_statuses)
      generate_and_write_for_all_examples(
        all_examples, ES_HTML_YML_PATH, glfm_examples_statuses: glfm_examples_statuses
      ) do |example, hash, existing_hash|
        name = example.fetch(:name).to_sym
        example_statuses = glfm_examples_statuses[name] || {}

        static = if example_statuses[:skip_update_example_snapshot_html_static]
                   existing_hash.dig(name, :static)
                 else
                   static_html_hash[name]
                 end

        wysiwyg = if example_statuses[:skip_update_example_snapshot_html_wysiwyg]
                    existing_hash.dig(name, :wysiwyg)
                  else
                    wysiwyg_html_and_json_hash.dig(name, :html)
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
        all_examples, ES_PROSEMIRROR_JSON_YML_PATH, glfm_examples_statuses: glfm_examples_statuses
      ) do |example, hash, existing_hash|
        name = example.fetch(:name).to_sym

        json = if glfm_examples_statuses.dig(name, :skip_update_example_snapshot_prosemirror_json)
                 existing_hash[name]
               else
                 wysiwyg_html_and_json_hash.dig(name, :json)
               end

        # Do not assign nil values
        hash[name] = json if json
      end
    end

    def generate_and_write_for_all_examples(
      all_examples, output_file_path, glfm_examples_statuses: {}, literal_scalars: true
    )
      preserve_existing = !glfm_examples_statuses.empty?
      output("#{preserve_existing ? 'Creating/Updating' : 'Creating/Overwriting'} #{output_file_path}...")
      existing_hash = preserve_existing ? YAML.safe_load(File.open(output_file_path), symbolize_names: true) : {}

      output_hash = all_examples.each_with_object({}) do |example, hash|
        name = example.fetch(:name).to_sym
        if (reason = glfm_examples_statuses.dig(name, :skip_update_example_snapshots))
          # Output the reason for skipping the example, but only once, not multiple times for each file
          output("Skipping '#{name}'. Reason: #{reason}") unless glfm_examples_statuses.dig(name, :already_printed)
          # We just store the `:already_printed` flag in the hash entry itself. Then we
          # don't need an instance variable to keep the state, and this can remain a pure function ;)
          glfm_examples_statuses[name][:already_printed] = true

          # Copy over the existing example only if it exists and preserve_existing is true, otherwise omit this example
          hash[name] = existing_hash[name] if existing_hash[name]

          next
        end

        yield(example, hash, existing_hash)
      end

      yaml_string = dump_yaml_with_formatting(output_hash, literal_scalars: literal_scalars)
      write_file(output_file_path, yaml_string)
    end
  end
end
