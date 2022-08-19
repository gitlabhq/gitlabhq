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
# the API # and obtain the response.
#
# It is intended to be invoked as a helper subprocess from the `update_example_snapshots.rb`
# script class. It's not intended to be run or used directly. This usage is also reinforced
# by not naming the file with a `_spec.rb` ending.
RSpec.describe 'Render Static HTML', :api, type: :request do # rubocop:disable RSpec/TopLevelDescribePath
  include Glfm::Constants
  include Glfm::Shared

  let(:user) { create(:user, :admin, username: 'glfm_user') }

  before do
    stub_licensed_features(group_wikis: true)

    group = create(:group, name: 'glfm_group')
    group.add_owner(user)

    project = create(:project, :repository, creator: user, group: group, name: 'glfm_project')

    # NOTE: We hardcode the IDs on all fixtures to prevent variability in the
    #       rendered HTML/Prosemirror JSON, and to minimize the need for normalization:
    #       https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#normalization
    create(:project_snippet, id: 88888, project: project) # project snippet
    create(:snippet, id: 99999) # personal snippet

    sign_in(user)
  end

  it 'can create a project dependency graph using factories' do
    markdown_hash = YAML.load_file(ENV.fetch('INPUT_MARKDOWN_YML_PATH'))

    # NOTE: We cannot parallelize this loop like the Javascript WYSIWYG example generation does,
    # because the rspec `post` API cannot be parallized (it is not thread-safe, it can't find
    # the controller).
    static_html_hash = markdown_hash.transform_values do |markdown|
      api_url = api "/markdown"

      post api_url, params: { text: markdown, gfm: true }

      returned_html_value =
        begin
          parsed_response = Gitlab::Json.parse(response.body)
          # The response may contain the HTML in either the `body` or `html` keys
          parsed_response['body'] || parsed_response['html']
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
    tmpfile = File.open(ENV.fetch('OUTPUT_STATIC_HTML_TEMPFILE_PATH'), 'w')
    YAML.dump(static_html_hash, tmpfile)
    tmpfile.close
  end
end
