# frozen_string_literal: true

require 'spec_helper'
require_relative 'constants'
require_relative 'shared'

# Purpose:
# - Reads a set of markdown examples from a hash which has been serialized to disk
# - Sets up the appropriate fixture data for the markdown examples
# - Converts each example to static HTML using the appropriate API markdown endpoint
# - Writes the HTML for each example to a hash which is serialized to disk
#
# Requirements:
# The input and output files are specified via these environment variables:
# - INPUT_MARKDOWN_YML_PATH
# - OUTPUT_STATIC_HTML_TEMPFILE_PATH
#
# Although it is implemented as an RSpec test, it is not a unit test. We use
# RSpec because that is the simplest environment in which we can use the
# Factorybot factory methods to create persisted model objects with stable
# and consistent data values, to ensure consistent example snapshot HTML
# across various machines and environments. RSpec also makes it easy to invoke
# the API and obtain the response.
#
# It is intended to be invoked as a helper subprocess from the `update_example_snapshots.rb`
# and `update_specification.rb` script classes. It's not intended to be run or used directly.
# This usage is also reinforced by not naming the file with a `_spec.rb` ending.
RSpec.describe 'Render Static HTML', :api, type: :request do
  include Glfm::Constants
  include Glfm::Shared

  # noinspection RailsParamDefResolve (RubyMine can't find the shared context from this file location)
  include_context 'with GLFM example snapshot fixtures'

  it do
    markdown_hash = YAML.safe_load(File.open(ENV.fetch('INPUT_MARKDOWN_YML_PATH')), symbolize_names: true)
    metadata_hash =
      if input_metadata_yml_path = ENV['INPUT_METADATA_YML_PATH']
        YAML.safe_load(File.open(input_metadata_yml_path), symbolize_names: true) || {}
      else
        {}
      end

    # NOTE: We cannot parallelize this loop like the Javascript WYSIWYG example generation does,
    # because the rspec `post` API cannot be parallized (it is not thread-safe, it can't find
    # the controller).
    static_html_hash = markdown_hash.transform_values.with_index do |markdown, index|
      name = markdown_hash.keys[index]
      api_url = metadata_hash.dig(name, :api_request_override_path) || (api "/markdown")

      post api_url, params: { text: markdown, gfm: true }
      # noinspection RubyResolve
      expect(response).to be_successful

      returned_html_value =
        begin
          parsed_response = Gitlab::Json.parse(response.body, symbolize_names: true)
          # Some responses have the HTML in the `html` key, others in the `body` key.
          parsed_response[:body] || parsed_response[:html]
        rescue JSON::ParserError
          # if we got a parsing error, just return the raw response body for debugging purposes.
          response.body
        end

      returned_html_value
    end

    write_output_file(static_html_hash)
  end

  private

  def write_output_file(static_html_hash)
    yaml_string = dump_yaml_with_formatting(static_html_hash)
    write_file(ENV.fetch('OUTPUT_STATIC_HTML_TEMPFILE_PATH'), yaml_string)
  end
end
