# frozen_string_literal: true

require 'pathname'

module Glfm
  module Constants
    # Version and titles for rendering
    GLFM_SPEC_VERSION = 'alpha'
    GLFM_SPEC_TXT_TITLE = 'GitLab Flavored Markdown Official Specification'
    ES_SNAPSHOT_SPEC_TITLE = 'GitLab Flavored Markdown Internal Extensions'

    # Root dir containing all specification files
    specification_path = Pathname.new(File.expand_path("../../../glfm_specification", __dir__))

    # GitHub Flavored Markdown specification file
    GHFM_SPEC_TXT_URI = 'https://raw.githubusercontent.com/github/cmark-gfm/master/test/spec.txt'
    GHFM_SPEC_VERSION = '0.29'
    GHFM_SPEC_MD_FILENAME = "ghfm_spec_v_#{GHFM_SPEC_VERSION}.md"
    GHFM_SPEC_MD_PATH = specification_path.join('input/github_flavored_markdown', GHFM_SPEC_MD_FILENAME)

    # GitLab Flavored Markdown specification files
    specification_input_glfm_path = specification_path.join('input/gitlab_flavored_markdown')
    GLFM_OFFICIAL_SPECIFICATION_MD_PATH =
      specification_input_glfm_path.join('glfm_official_specification.md')
    GLFM_INTERNAL_EXTENSIONS_MD_PATH = specification_input_glfm_path.join('glfm_internal_extensions.md')
    GLFM_EXAMPLE_STATUS_YML_PATH = specification_input_glfm_path.join('glfm_example_status.yml')
    GLFM_EXAMPLE_METADATA_YML_PATH =
      specification_input_glfm_path.join('glfm_example_metadata.yml')
    GLFM_EXAMPLE_NORMALIZATIONS_YML_PATH = specification_input_glfm_path.join('glfm_example_normalizations.yml')
    GLFM_OUTPUT_SPEC_PATH = specification_path.join('output_spec')
    GLFM_SPEC_TXT_PATH = GLFM_OUTPUT_SPEC_PATH.join('spec.txt')
    GLFM_SPEC_HTML_PATH = GLFM_OUTPUT_SPEC_PATH.join('spec.html')
    GLFM_SPEC_TXT_HEADER = <<~MARKDOWN
      ---
      title: #{GLFM_SPEC_TXT_TITLE}
      version: #{GLFM_SPEC_VERSION}
      ...
    MARKDOWN

    # Example Snapshot (ES) files
    ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH = specification_path.join('output_example_snapshots')
    ES_SNAPSHOT_SPEC_MD_PATH = ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH.join('snapshot_spec.md')
    ES_SNAPSHOT_SPEC_HTML_PATH = ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH.join('snapshot_spec.html')
    ES_EXAMPLES_INDEX_YML_PATH = ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH.join('examples_index.yml')
    ES_MARKDOWN_YML_PATH = ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH.join('markdown.yml')
    ES_HTML_YML_PATH = ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH.join('html.yml')
    ES_PROSEMIRROR_JSON_YML_PATH = ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH.join('prosemirror_json.yml')
    ES_SNAPSHOT_SPEC_MD_HEADER = <<~MARKDOWN
      ---
      title: #{ES_SNAPSHOT_SPEC_TITLE}
      version: #{GLFM_SPEC_VERSION}
      ...
    MARKDOWN

    # Other constants used for processing files
    EXAMPLE_BACKTICKS_LENGTH = 32
    EXAMPLE_BACKTICKS_STRING = '`' * EXAMPLE_BACKTICKS_LENGTH
    EXAMPLE_BEGIN_STRING = "#{EXAMPLE_BACKTICKS_STRING} example"
    EXAMPLE_END_STRING = EXAMPLE_BACKTICKS_STRING
    INTRODUCTION_HEADER_LINE_TEXT = '# Introduction'
    BEGIN_TESTS_COMMENT_LINE_TEXT = '<!-- BEGIN TESTS -->'
    END_TESTS_COMMENT_LINE_TEXT = '<!-- END TESTS -->'
    MARKDOWN_TEMPFILE_BASENAME = %w[MARKDOWN_TEMPFILE_ .yml].freeze
    METADATA_TEMPFILE_BASENAME = %w[METADATA_TEMPFILE_ .yml].freeze
    STATIC_HTML_TEMPFILE_BASENAME = %w[STATIC_HTML_TEMPFILE_ .yml].freeze
    WYSIWYG_HTML_AND_JSON_TEMPFILE_BASENAME = %w[WYSIWYG_HTML_AND_JSON_TEMPFILE_ .yml].freeze
  end
end
